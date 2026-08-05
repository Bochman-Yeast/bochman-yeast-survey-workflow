#!/usr/bin/env python3
"""Fallback ITS extraction: the interval between the 18S and 28S rRNA genes
called by barrnap (ITS1-5.8S-ITS2), used only when ITSx finds no confident hit.
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
    gff, asm, out_fa, sample = sys.argv[1:5]
    feats = parse_gff(gff)
    ssu = [f for f in feats if "18S_rRNA" in f["attrs"]]
    lsu = [f for f in feats if "28S_rRNA" in f["attrs"]]
    if not ssu or not lsu:
        sys.stderr.write("Missing 18S or 28S feature; cannot extract ITS interval\n")
        sys.exit(1)

    seqs = SeqIO.to_dict(SeqIO.parse(asm, "fasta"))
    best = None  # (seqid, start0, end0, strand, gap)
    for s in ssu:
        for l in lsu:
            if s["seqid"] != l["seqid"] or s["strand"] != l["strand"]:
                continue
            if s["strand"] == "+" and l["start"] > s["end"]:
                gap = l["start"] - s["end"]
                cand = (s["seqid"], s["end"], l["start"] - 1, "+", gap)
            elif s["strand"] == "-" and s["start"] > l["end"]:
                gap = s["start"] - l["end"]
                cand = (s["seqid"], l["end"], s["start"] - 1, "-", gap)
            else:
                continue
            if best is None or cand[4] < best[4]:
                best = cand

    if best is None:
        sys.stderr.write("No adjacent 18S/28S pair found on same seqid/strand\n")
        sys.exit(1)

    seqid, start, end, strand, gap = best
    sub = seqs[seqid].seq[start:end]
    if strand == "-":
        sub = sub.reverse_complement()
    with open(out_fa, "w") as out:
        out.write(f">{sample}_ITS_interval {seqid}:{start+1}-{end}({strand}) gap={gap}bp\n")
        out.write(str(sub) + "\n")


if __name__ == "__main__":
    main()
