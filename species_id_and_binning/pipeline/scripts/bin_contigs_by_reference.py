#!/usr/bin/env python3
"""Bin assembly contigs by which of two references they align better to.

Sums matching aligned bases per contig per reference from minimap2 PAF
output (asm preset), assigns each contig to whichever reference has more
aligned bases, and writes per-reference contig-subset FASTAs plus a
summary table. Contigs with negligible alignment to both are left unassigned.
"""
import sys
from collections import defaultdict
from Bio import SeqIO

MIN_ALIGNED_FRACTION = 0.1  # contig must have >=10% of its length aligned to count


def paf_aligned_bases(paf_path):
    totals = defaultdict(int)
    with open(paf_path) as fh:
        for line in fh:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 11:
                continue
            qname, matching = cols[0], int(cols[9])
            totals[qname] += matching
    return totals


def main():
    paf1, name1, paf2, name2, asm_fasta, outdir = sys.argv[1:7]
    aligned1 = paf_aligned_bases(paf1)
    aligned2 = paf_aligned_bases(paf2)

    contigs = SeqIO.to_dict(SeqIO.parse(asm_fasta, "fasta"))
    rows = []
    bins = {name1: [], name2: [], "unassigned": []}
    for cid, rec in contigs.items():
        clen = len(rec.seq)
        a1 = aligned1.get(cid, 0)
        a2 = aligned2.get(cid, 0)
        frac1, frac2 = a1 / clen, a2 / clen
        if frac1 < MIN_ALIGNED_FRACTION and frac2 < MIN_ALIGNED_FRACTION:
            assigned = "unassigned"
        elif a1 >= a2:
            assigned = name1
        else:
            assigned = name2
        bins[assigned].append(cid)
        rows.append((cid, clen, a1, frac1, a2, frac2, assigned))

    with open(f"{outdir}/contig_bins.tsv", "w") as out:
        out.write(f"contig\tlength\taligned_bases_{name1}\tfraction_{name1}\t"
                   f"aligned_bases_{name2}\tfraction_{name2}\tassigned\n")
        for r in sorted(rows, key=lambda x: -x[1]):
            out.write(f"{r[0]}\t{r[1]}\t{r[2]}\t{r[3]:.3f}\t{r[4]}\t{r[5]:.3f}\t{r[6]}\n")

    for label, cids in bins.items():
        if not cids:
            continue
        fname = f"{outdir}/contigs_unassigned.fasta" if label == "unassigned" else f"{outdir}/contigs_{label}.fasta"
        with open(fname, "w") as out:
            for cid in cids:
                SeqIO.write(contigs[cid], out, "fasta")

    total_len = sum(len(r.seq) for r in contigs.values())
    print(f"Total assembly length: {total_len:,} bp across {len(contigs)} contigs")
    for label, cids in bins.items():
        blen = sum(len(contigs[c].seq) for c in cids)
        pct = 100 * blen / total_len if total_len else 0
        print(f"  {label}: {len(cids)} contigs, {blen:,} bp ({pct:.1f}%)")


if __name__ == "__main__":
    main()
