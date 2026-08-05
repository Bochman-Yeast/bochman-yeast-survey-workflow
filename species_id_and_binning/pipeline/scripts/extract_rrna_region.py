#!/usr/bin/env python3
"""Slice out a padded window around the rRNA locus (18S...28S) from a barrnap
GFF3 + assembly. ITSx's HMMER pipeline caps single-sequence input at 100kb,
so ITSx must run on this extracted region, not the whole assembly/contig.
"""
import sys
from Bio import SeqIO


def parse_gff(gff_path):
    feats = []
    with open(gff_path) as fh:
        for line in fh:
            if line.startswith("#") or not line.strip():
                continue
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 9:
                continue
            feats.append({
                "seqid": cols[0], "start": int(cols[3]), "end": int(cols[4]),
                "strand": cols[6], "attrs": cols[8],
            })
    return feats


def main():
    gff, asm, out_fa, sample, padding = sys.argv[1:6]
    padding = int(padding)
    feats = parse_gff(gff)
    ssu = [f for f in feats if "18S_rRNA" in f["attrs"]]
    lsu = [f for f in feats if "28S_rRNA" in f["attrs"]]
    if not ssu or not lsu:
        sys.stderr.write("Missing 18S or 28S feature; cannot bound rRNA region\n")
        sys.exit(1)

    seqs = SeqIO.to_dict(SeqIO.parse(asm, "fasta"))
    best = None  # (seqid, start0, end0, strand, gap)
    for s in ssu:
        for l in lsu:
            if s["seqid"] != l["seqid"] or s["strand"] != l["strand"]:
                continue
            if s["strand"] == "+" and l["start"] > s["end"]:
                gap = l["start"] - s["end"]
                cand = (s["seqid"], s["start"], l["end"], "+", gap)
            elif s["strand"] == "-" and s["start"] > l["end"]:
                gap = s["start"] - l["end"]
                cand = (s["seqid"], l["start"], s["end"], "-", gap)
            else:
                continue
            if best is None or cand[4] < best[4]:
                best = cand

    if best is None:
        sys.stderr.write("No adjacent 18S/28S pair found on same seqid/strand\n")
        sys.exit(1)

    seqid, start, end, strand, gap = best
    rec = seqs[seqid]
    lo = max(0, start - 1 - padding)
    hi = min(len(rec.seq), end + padding)
    sub = rec.seq[lo:hi]
    if strand == "-":
        sub = sub.reverse_complement()
    with open(out_fa, "w") as out:
        out.write(f">{sample}_rRNA_region {seqid}:{lo+1}-{hi}({strand}) its_gap={gap}bp\n")
        out.write(str(sub) + "\n")


if __name__ == "__main__":
    main()
