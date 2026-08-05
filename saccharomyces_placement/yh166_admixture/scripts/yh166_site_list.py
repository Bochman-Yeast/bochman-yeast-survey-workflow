#!/usr/bin/env python3
import sys, gzip

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"

panel_sites = set()
with open(f"{PROJ}/placement/all_panel_sites.tsv") as f:
    for line in f:
        chrom, pos = line.strip().split("\t")
        panel_sites.add((chrom, int(pos)))

out = open(f"{PROJ}/placement/yh166_het_sites.tsv", "w")
n = 0
with gzip.open(f"{PROJ}/calls/YH166/merge_output.vcf.gz", "rt") as f:
    for line in f:
        if line.startswith("#"):
            continue
        parts = line.rstrip("\n").split("\t")
        chrom, pos, ref, alt = parts[0], int(parts[1]), parts[3], parts[4]
        if len(ref) != 1 or len(alt) != 1:
            continue
        if (chrom, pos) not in panel_sites:
            continue
        fmt = parts[8].split(":")
        gt = parts[9].split(":")[fmt.index("GT")].replace("|", "/")
        alleles = gt.split("/")
        if len(set(alleles)) < 2:
            continue
        out.write(f"{chrom}\t{pos}\t{ref}\t{alt}\n")
        n += 1
out.close()
print(f"Wrote {n} heterozygous, panel-overlapping sites for YH166", file=sys.stderr)
