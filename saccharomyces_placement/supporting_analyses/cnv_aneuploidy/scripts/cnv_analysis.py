#!/usr/bin/env python3
import sys, csv

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"
SAMPLES = ["YH123", "YH166", "YH196", "YH229", "DoF1"]

print("=== Chromosome-level relative copy number (samtools coverage) ===")
print(f"{'sample':8s} {'chrom':14s} {'meandepth':>10s} {'rel_copy_number':>16s} {'flag':>6s}")
for s in SAMPLES:
    rows = []
    with open(f"{PROJ}/cnv/{s}.coverage.txt") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            rows.append(row)
    total_bases = sum(int(r["endpos"]) - int(r["startpos"]) for r in rows)
    weighted_depth = sum(float(r["meandepth"]) * (int(r["endpos"]) - int(r["startpos"])) for r in rows) / total_bases
    for r in rows:
        chrom = r["#rname"]
        meandepth = float(r["meandepth"])
        rel = meandepth / weighted_depth
        flag = ""
        if rel > 1.3:
            flag = "HIGH"
        elif rel < 0.7:
            flag = "LOW"
        print(f"{s:8s} {chrom:14s} {meandepth:10.1f} {rel:16.3f} {flag:>6s}")
    print()

print("DONE", file=sys.stderr)
