#!/usr/bin/env python3
import sys, gzip, statistics

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"
SAMPLES = ["YH123", "YH166", "YH196", "YH229", "DoF1"]
HIGH_THRESH = 2.0
LOW_THRESH = 0.3
MIN_RUN_BINS = 3

for s in SAMPLES:
    path = f"{PROJ}/cnv/{s}_1kb.regions.bed.gz"
    bins = []
    with gzip.open(path, "rt") as f:
        for line in f:
            chrom, start, end, depth = line.rstrip("\n").split("\t")
            bins.append((chrom, int(start), int(end), float(depth)))
    depths = [b[3] for b in bins]
    genome_mean = statistics.mean(depths)

    outlier_runs = []
    current_run = []
    for chrom, start, end, depth in bins:
        rel = depth / genome_mean if genome_mean else 0
        is_outlier = rel > HIGH_THRESH or rel < LOW_THRESH
        if is_outlier and (not current_run or current_run[-1][0] == chrom):
            current_run.append((chrom, start, end, rel))
        else:
            if len(current_run) >= MIN_RUN_BINS:
                outlier_runs.append(current_run)
            current_run = [(chrom, start, end, rel)] if is_outlier else []
    if len(current_run) >= MIN_RUN_BINS:
        outlier_runs.append(current_run)

    print(f"=== {s}: genome-wide mean depth = {genome_mean:.1f}x, {len(outlier_runs)} outlier run(s) >= {MIN_RUN_BINS} consecutive 1kb bins ===")
    for run in outlier_runs:
        chrom = run[0][0]
        start = run[0][1]
        end = run[-1][2]
        kind = "HIGH" if run[0][3] > 1 else "LOW"
        mean_rel = sum(r[3] for r in run) / len(run)
        print(f"  {chrom}:{start}-{end}  ({end-start} bp, {len(run)} bins)  {kind}  mean_rel_depth={mean_rel:.2f}x")
    print()

print("DONE", file=sys.stderr)
