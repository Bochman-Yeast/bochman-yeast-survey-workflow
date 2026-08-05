#!/usr/bin/env python3
import sys, gzip, statistics

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"
SAMPLES = ["YH123", "YH166", "YH196", "YH229", "DoF1"]
HIGH_THRESH = 2.0
LOW_THRESH = 0.3
MIN_RUN_BINS = 3
OVERLAP_SLOP = 3000

per_sample_runs = {}

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

    regions = []
    for run in outlier_runs:
        chrom = run[0][0]
        start = run[0][1]
        end = run[-1][2]
        mean_rel = sum(r[3] for r in run) / len(run)
        regions.append((chrom, start, end, mean_rel))
    per_sample_runs[s] = regions

def overlaps(a, b):
    return a[0] == b[0] and a[1] - OVERLAP_SLOP <= b[2] and b[1] - OVERLAP_SLOP <= a[2]

print("=== Isolate-specific CNV candidates (outlier in <=2 of 5 samples, i.e. NOT a shared mapping artifact) ===\n")
seen = set()
for s in SAMPLES:
    for region in per_sample_runs[s]:
        key = (s, region[0], region[1])
        if key in seen:
            continue
        matches = [s]
        for other in SAMPLES:
            if other == s:
                continue
            for other_region in per_sample_runs[other]:
                if overlaps(region, other_region):
                    matches.append(other)
                    break
        if len(matches) <= 2:
            direction = "HIGH" if region[3] > 1 else "LOW"
            print(f"  {region[0]}:{region[1]}-{region[2]}  {direction}  rel_depth={region[3]:.2f}x  "
                  f"present_in={matches}  ({region[2]-region[1]} bp)")
        for m in matches:
            seen.add((m, region[0], region[1]))

print(f"\n=== Shared-artifact region count (present in >=3/5 samples, likely reference mapping issue) ===")
shared_count = 0
seen2 = set()
for s in SAMPLES:
    for region in per_sample_runs[s]:
        key = (s, region[0], region[1])
        if key in seen2:
            continue
        matches = [s]
        for other in SAMPLES:
            if other == s:
                continue
            for other_region in per_sample_runs[other]:
                if overlaps(region, other_region):
                    matches.append(other)
                    break
        if len(matches) >= 3:
            shared_count += 1
        for m in matches:
            seen2.add((m, region[0], region[1]))
print(f"  {shared_count} shared regions (not itemized - consistent with Ty/LTR/subtelomeric repeat artifacts)")

print("\nDONE", file=sys.stderr)
