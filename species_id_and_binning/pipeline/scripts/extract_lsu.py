#!/usr/bin/env python3
"""Extract the D1/D2 domain of the 28S/LSU rRNA gene from a barrnap GFF3 + assembly.

D1/D2 sits at the 5' end of the large-subunit rRNA gene, so this takes the
first N bp of the longest 28S_rRNA feature, respecting strand.
"""
import sys
from Bio import SeqIO


def parse_gff(gff_path, name_substr):
    feats = []
    with open(gff_path) as fh:
        for line in fh:
            if line.startswith("#") or not line.strip():
                continue
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 9 or name_substr not in cols[8]:
                continue
            feats.append({
                "seqid": cols[0], "start": int(cols[3]), "end": int(cols[4]),
                "strand": cols[6],
            })
    return feats


def main():
    gff, asm, out_fa, sample, length = sys.argv[1:6]
    length = int(length)
    feats = parse_gff(gff, "28S_rRNA")
    if not feats:
        sys.stderr.write(f"No 28S_rRNA feature found in {gff}\n")
        sys.exit(1)
    best = max(feats, key=lambda f: f["end"] - f["start"])
    seqs = SeqIO.to_dict(SeqIO.parse(asm, "fasta"))
    rec = seqs[best["seqid"]]
    if best["strand"] == "-":
        sub = rec.seq[max(0, best["end"] - length):best["end"]].reverse_complement()
    else:
        sub = rec.seq[best["start"] - 1: best["start"] - 1 + length]
    with open(out_fa, "w") as out:
        out.write(f">{sample}_LSU_D1D2 {best['seqid']}:{best['start']}-{best['end']}({best['strand']})\n")
        out.write(str(sub) + "\n")


if __name__ == "__main__":
    main()
