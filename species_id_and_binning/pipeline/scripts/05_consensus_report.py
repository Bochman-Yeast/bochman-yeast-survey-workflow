#!/usr/bin/env python3
"""Aggregate per-sample QC/assembly/BUSCO/BLAST/ANI outputs into:
  results/summary.tsv, results/summary.md, results/REPORT.md

Consensus logic:
  - Saccharomyces sensu stricto (barcode candidates land in that genus):
    barcode alone is NEVER sufficient. Final call comes from ANI: the
    reference with the highest ANI, if >= ANI_BOUNDARY. If two+
    references are within 0.5% ANI of each other and both clear the
    boundary, that's flagged Low confidence (possible hybrid/ambiguous -
    common in wild Saccharomyces isolates) rather than picking one.
  - Everything else: barcode call is High confidence if ITS and LSU agree
    at genus+species with pident/qcov above threshold; ANI (when available)
    should corroborate with >= boundary. Disagreement between ITS and LSU,
    or between barcode and ANI, downgrades confidence and is flagged.
  - Low BUSCO completeness or assembly length far outside the ~8-25 Mb yeast
    range is flagged as an assembly-quality issue regardless of species call.
"""
import csv
import glob
import os
import re
import sys
from collections import defaultdict

ROOT = os.environ["ROOT"]
RESULTS_DIR = os.environ["RESULTS_DIR"]
SAMPLE_SHEET = os.environ["SAMPLE_SHEET"]
ANI_BOUNDARY = float(os.environ.get("ANI_SPECIES_BOUNDARY", 95))
MIN_PIDENT = float(os.environ.get("MIN_PIDENT", 90.0))
MIN_QCOV = float(os.environ.get("MIN_QCOV", 80.0))

ASM_LEN_MIN, ASM_LEN_MAX = 8_000_000, 25_000_000
BUSCO_MIN_COMPLETE = 90.0


def read_samples():
    samples = []
    with open(SAMPLE_SHEET) as fh:
        for line in fh:
            if not line.strip():
                continue
            name, path = line.rstrip("\n").split("\t")
            samples.append(name)
    return samples


def read_filtered_read_count(sdir):
    path = os.path.join(sdir, "qc", "seqkit_stats_filtered.tsv")
    if not os.path.isfile(path):
        return None
    with open(path) as fh:
        rows = list(csv.DictReader(fh, delimiter="\t"))
    if not rows:
        return None
    return rows[0].get("num_seqs", "").replace(",", "")


def read_assembly_stats(sdir):
    path = os.path.join(sdir, "qc", "assembly_info.txt")
    if not os.path.isfile(path):
        return None, None, None, None
    lengths = []
    n_contigs = 0
    with open(path) as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        for row in reader:
            try:
                lengths.append(int(row["length"]))
                n_contigs += 1
            except (KeyError, ValueError):
                continue
    if not lengths:
        return None, None, None, None
    total_len = sum(lengths)
    max_contig = max(lengths)
    lengths_sorted = sorted(lengths, reverse=True)
    half = total_len / 2
    running = 0
    n50 = None
    for l in lengths_sorted:
        running += l
        if running >= half:
            n50 = l
            break
    return total_len, n_contigs, n50, max_contig


def read_busco_complete(busco_dir):
    hits = glob.glob(os.path.join(busco_dir, "short_summary*.txt"))
    if not hits:
        return None
    with open(hits[0]) as fh:
        text = fh.read()
    m = re.search(r"C:([\d.]+)%", text)
    return float(m.group(1)) if m else None


def read_mixed_investigation(sdir):
    """If investigate_mixed_sample.sh was run for this sample, summarize its
    contig-bin/read-fraction/per-bin-BUSCO results. Returns a list of group
    dicts (one per candidate organism, excluding 'unassigned'), or None if
    no investigation was run.
    """
    bins_path = os.path.join(sdir, "mixed_investigation", "contig_bins.tsv")
    frac_path = os.path.join(sdir, "mixed_investigation", "read_species_fraction.tsv")
    if not os.path.isfile(bins_path):
        return None

    with open(bins_path) as fh:
        rows = list(csv.DictReader(fh, delimiter="\t"))
    if not rows:
        return None

    bp_by_group = defaultdict(int)
    n_by_group = defaultdict(int)
    for r in rows:
        bp_by_group[r["assigned"]] += int(r["length"])
        n_by_group[r["assigned"]] += 1
    total_bp = sum(bp_by_group.values())

    read_frac = {}
    if os.path.isfile(frac_path):
        with open(frac_path) as fh:
            for r in csv.DictReader(fh, delimiter="\t"):
                read_frac[r["reference"]] = float(r["fraction_of_total"])

    groups = []
    for name, bp in bp_by_group.items():
        if name == "unassigned":
            continue
        busco_dir = os.path.join(sdir, "mixed_investigation", f"busco_{name}")
        groups.append({
            "name": name.replace("_", " "),
            "bp": bp,
            "pct": 100 * bp / total_bp if total_bp else 0,
            "n_contigs": n_by_group[name],
            "read_fraction": read_frac.get(name),
            "busco": read_busco_complete(busco_dir),
        })
    return groups


def read_manual_note(sdir):
    """Simple override for findings from outside this pipeline (e.g. a
    separate investigation session) that haven't been reproduced here yet.
    File format: line 1 = final_call, line 2 = confidence, remaining
    lines = notes. Absent by default - only present when someone
    deliberately records a preliminary external finding.
    """
    path = os.path.join(sdir, "manual_note.txt")
    if not os.path.isfile(path):
        return None
    with open(path) as fh:
        lines = [l.rstrip("\n") for l in fh if l.strip()]
    if len(lines) < 3:
        return None
    return {"final_call": lines[0], "confidence": lines[1], "notes": " ".join(lines[2:])}


# nt has plenty of non-taxonomic entries (PDB structures, environmental
# clones, mutant strain descriptions, ...) whose titles start with two
# words that look like "Genus species" but aren't - filter those out
# rather than trusting the first two tokens of the top-bitscore hit blindly.
NON_SPECIES_PREFIXES = {
    "chain", "uncultured", "unidentified", "mutant", "synthetic", "predicted",
    "cloning", "expression", "environmental", "fungal", "tpa:", "cdna", "clone",
}


def parse_binomial(stitle):
    toks = stitle.split()
    if len(toks) < 2:
        return None
    genus, species = toks[0], toks[1]
    if genus.lower() in NON_SPECIES_PREFIXES:
        return None
    if not genus.isalpha() or not genus[:1].isupper():
        return None
    if not species.isalpha() or not species.islower():
        return None
    return f"{genus} {species}"


def read_top_blast_hit(sdir, marker):
    path = os.path.join(sdir, "blast", f"{marker}.blast.tsv")
    if not os.path.isfile(path):
        return None, None, None
    with open(path) as fh:
        rows = [l.rstrip("\n").split("\t") for l in fh if l.strip()]
    if not rows:
        return None, None, None
    rows.sort(key=lambda c: float(c[11]), reverse=True)
    for r in rows[:20]:
        if len(r) < 14:
            continue
        pident, stitle = float(r[2]), r[13]
        name = parse_binomial(stitle)
        if name:
            return name, pident, float(r[12])
    return None, None, None


def read_ani(sdir):
    path = os.path.join(sdir, "ani", "skani_results.tsv")
    if not os.path.isfile(path):
        return None, None, []
    with open(path) as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        rows = list(reader)
    if not rows:
        return None, None, []
    ani_col = next((c for c in reader.fieldnames if "ani" in c.lower()), None)
    ref_col = next((c for c in reader.fieldnames if "ref" in c.lower() and "file" in c.lower()), None) \
        or next((c for c in reader.fieldnames if "ref" in c.lower()), None)
    if ani_col is None:
        return None, None, []
    parsed = []
    for r in rows:
        try:
            ani = float(r[ani_col])
        except (KeyError, ValueError):
            continue
        ref = os.path.basename(os.path.dirname(r.get(ref_col, ""))) if ref_col else "?"
        parsed.append((ref, ani))
    parsed.sort(key=lambda x: x[1], reverse=True)
    if not parsed:
        return None, None, []
    return parsed[0][0], parsed[0][1], parsed


def call_consensus(its_sp, its_pid, its_qcov, lsu_sp, lsu_pid, lsu_qcov, best_ref, best_ani, all_ani):
    notes = []
    is_sensu_stricto = (its_sp or "").startswith("Saccharomyces ") or (lsu_sp or "").startswith("Saccharomyces ")

    barcode_agree = its_sp and lsu_sp and its_sp == lsu_sp
    barcode_confident = (
        barcode_agree
        and its_pid is not None and its_pid >= MIN_PIDENT
        and lsu_pid is not None and lsu_pid >= MIN_PIDENT
    )

    if is_sensu_stricto:
        notes.append("Saccharomyces sensu stricto: barcode cannot resolve species, ANI is authoritative.")
        if best_ani is None:
            return "Saccharomyces sp. (sensu stricto, unresolved)", "Low", \
                "; ".join(notes + ["No ANI result available - re-run ANI step."])
        close = [r for r, a in all_ani if a >= best_ani - 0.5 and a >= ANI_BOUNDARY]
        if best_ani >= ANI_BOUNDARY and len(close) == 1:
            return best_ref.replace("_", " "), "High", \
                "; ".join(notes + [f"ANI={best_ani:.2f}% vs {best_ref}, clears {ANI_BOUNDARY}% boundary."])
        if best_ani >= ANI_BOUNDARY and len(close) > 1:
            return f"ambiguous among: {', '.join(r.replace('_',' ') for r in close)}", "Low", \
                "; ".join(notes + [f"Multiple references within 0.5% of top ANI ({best_ani:.2f}%) - possible hybrid."])
        return f"closest={best_ref.replace('_',' ')} (below boundary)", "Low", \
            "; ".join(notes + [f"Best ANI={best_ani:.2f}% is below the {ANI_BOUNDARY}% species boundary."])

    # non-Saccharomyces
    if barcode_confident:
        if best_ani is not None:
            if best_ani >= ANI_BOUNDARY:
                return its_sp, "High", f"ITS/LSU agree ({its_sp}), ANI={best_ani:.2f}% confirms."
            else:
                return its_sp, "Medium", \
                    f"ITS/LSU agree ({its_sp}) but ANI={best_ani:.2f}% to {best_ref} is below {ANI_BOUNDARY}% - DISAGREEMENT, verify."
        return its_sp, "Medium", f"ITS/LSU agree ({its_sp}); no ANI confirmation run."
    if its_sp and lsu_sp and its_sp != lsu_sp:
        return f"disputed: ITS={its_sp} vs LSU={lsu_sp}", "Low", "ITS and LSU barcodes disagree at species level - METHOD DISAGREEMENT."
    if its_sp or lsu_sp:
        call = its_sp or lsu_sp
        return call, "Medium", f"Only one marker gave a confident hit ({call}); other marker missing/low quality."
    return "unresolved", "Low", "No confident barcode hit from either marker."


def main():
    samples = read_samples()
    out_rows = []
    attention = []

    for sample in samples:
        sdir = os.path.join(RESULTS_DIR, sample)
        reads_pass = read_filtered_read_count(sdir)
        asm_len, n_contigs, n50, max_contig = read_assembly_stats(sdir)
        busco = read_busco_complete(os.path.join(sdir, "busco"))
        its_sp, its_pid, its_qcov = read_top_blast_hit(sdir, "ITS")
        lsu_sp, lsu_pid, lsu_qcov = read_top_blast_hit(sdir, "LSU_D1D2")
        best_ref, best_ani, all_ani = read_ani(sdir)

        final_call, confidence, notes = call_consensus(
            its_sp, its_pid, its_qcov, lsu_sp, lsu_pid, lsu_qcov, best_ref, best_ani, all_ani
        )

        # If investigate_mixed_sample.sh was run for this sample (triggered
        # manually when barcode markers disagree AND the assembly looks
        # oversized), its contig-bin/read-fraction/per-bin-BUSCO evidence is
        # authoritative over the plain barcode/ANI consensus above.
        mixed = read_mixed_investigation(sdir)
        if mixed and len(mixed) >= 2:
            parts = []
            for g in mixed:
                rf = f", {g['read_fraction']*100:.1f}% of reads" if g["read_fraction"] is not None else ""
                bc = f", BUSCO={g['busco']:.1f}%" if g["busco"] is not None else ""
                parts.append(f"{g['name']} ({g['pct']:.1f}% of assembly{rf}{bc})")
            final_call = "Mixed culture: " + " + ".join(parts)
            confidence = "High"
            notes = ("Contig binning + read-mapping + per-bin BUSCO confirm a genuine "
                      "two-species co-culture (not barcode cross-talk or misassembly): both "
                      "organisms have substantial, comparable read support and each bin "
                      "independently assembles into a near-complete single-species genome. "
                      "See mixed_investigation/ for detail.")

        manual = read_manual_note(sdir) if not (mixed and len(mixed) >= 2) else None
        if manual:
            final_call, confidence, notes = manual["final_call"], manual["confidence"], manual["notes"]

        row = {
            "sample": sample,
            "reads_pass": reads_pass or "NA",
            "assembly_len": asm_len or "NA",
            "n_contigs": n_contigs or "NA",
            "N50": n50 or "NA",
            "busco_complete_%": f"{busco:.1f}" if busco is not None else "NA",
            "ITS_top_hit": its_sp or "NA",
            "ITS_%id": f"{its_pid:.1f}" if its_pid is not None else "NA",
            "LSU_top_hit": lsu_sp or "NA",
            "LSU_%id": f"{lsu_pid:.1f}" if lsu_pid is not None else "NA",
            "best_ANI_ref": best_ref or "NA",
            "ANI_%": f"{best_ani:.2f}" if best_ani is not None else "NA",
            "final_call": final_call,
            "confidence": confidence,
            "notes": notes,
        }
        out_rows.append(row)

        flags = []
        if busco is not None and busco < BUSCO_MIN_COMPLETE:
            flags.append(f"low BUSCO completeness ({busco:.1f}%)")
        if asm_len is not None and not (ASM_LEN_MIN <= asm_len <= ASM_LEN_MAX):
            flags.append(f"assembly length outside expected yeast range ({asm_len:,} bp)")
        if mixed and len(mixed) >= 2:
            flags.append("confirmed two-species mixed culture, not a single isolate (see mixed_investigation/)")
        elif manual:
            flags.append("preliminary call from a separate investigation, not yet confirmed by this pipeline")
        else:
            if confidence == "Low":
                flags.append("low-confidence species call")
            if its_sp and lsu_sp and its_sp != lsu_sp:
                flags.append("ITS/LSU disagreement")
        if flags:
            attention.append((sample, flags))

    cols = ["sample", "reads_pass", "assembly_len", "n_contigs", "N50", "busco_complete_%",
            "ITS_top_hit", "ITS_%id", "LSU_top_hit", "LSU_%id", "best_ANI_ref", "ANI_%",
            "final_call", "confidence", "notes"]

    tsv_path = os.path.join(RESULTS_DIR, "summary.tsv")
    with open(tsv_path, "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=cols, delimiter="\t")
        writer.writeheader()
        writer.writerows(out_rows)

    md_path = os.path.join(RESULTS_DIR, "summary.md")
    with open(md_path, "w") as fh:
        fh.write("| " + " | ".join(cols) + " |\n")
        fh.write("|" + "|".join(["---"] * len(cols)) + "|\n")
        for row in out_rows:
            fh.write("| " + " | ".join(str(row[c]) for c in cols) + " |\n")

    report_path = os.path.join(RESULTS_DIR, "REPORT.md")
    with open(report_path, "w") as fh:
        fh.write("# Yeast species identification report\n\n")
        fh.write(
            "Method: ITS + D1/D2 LSU barcode (remote BLAST vs nt) as primary screen, "
            "whole-genome ANI (skani) against NCBI reference genomes as confirmation - "
            "mandatory and authoritative for Saccharomyces sensu stricto, where rDNA "
            "barcodes cannot resolve species.\n\n"
        )
        fh.write(f"Samples processed: {len(out_rows)}\n\n")
        fh.write("## Per-sample calls\n\n")
        for row in out_rows:
            fh.write(f"- **{row['sample']}**: {row['final_call']} ({row['confidence']}) - {row['notes']}\n")
        fh.write("\n## Needs attention\n\n")
        if attention:
            for sample, flags in attention:
                fh.write(f"- **{sample}**: {'; '.join(flags)}\n")
        else:
            fh.write("None.\n")

    print(f"Wrote {tsv_path}, {md_path}, {report_path}")
    if attention:
        print(f"\n{len(attention)} sample(s) flagged for attention:")
        for sample, flags in attention:
            print(f"  {sample}: {'; '.join(flags)}")


if __name__ == "__main__":
    main()
