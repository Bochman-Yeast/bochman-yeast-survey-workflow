#!/usr/bin/env python3
import sys
import pandas as pd

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"

meta = pd.read_csv(f"{PROJ}/metadata/panel_isolates.tsv", sep="\t")
superclade_lookup = meta.set_index("StandardizedName")["SuperClade"].to_dict()

with open(f"{PROJ}/placement/panel_sample_names.txt") as f:
    SAMPLES = [l.strip() for l in f]

yh166_alt = {}
with open(f"{PROJ}/placement/yh166_het_sites.tsv") as f:
    for line in f:
        chrom, pos, ref, alt = line.rstrip("\n").split("\t")
        yh166_alt[(chrom, pos)] = alt

freq_sum = {}
freq_n = {}
n_sites_processed = 0

with open(f"{PROJ}/placement/yh166_panel_genotypes.tsv") as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        chrom, pos = parts[0], parts[1]
        gts = parts[2:]
        key = (chrom, pos)
        if key not in yh166_alt:
            continue
        n_sites_processed += 1
        n_alt_by_super = {}
        n_total_by_super = {}
        for s, gt in zip(SAMPLES, gts):
            sc = superclade_lookup.get(s)
            if pd.isna(sc) or sc is None:
                sc = "Unassigned/Admixed"
            if gt in ("./.", ".|."):
                continue
            alleles = gt.replace("|", "/").split("/")
            n_alt = sum(1 for a in alleles if a == "1")
            n_total_by_super.setdefault(sc, 0)
            n_alt_by_super.setdefault(sc, 0)
            n_total_by_super[sc] += 2
            n_alt_by_super[sc] += n_alt
        for sc in n_total_by_super:
            if n_total_by_super[sc] == 0:
                continue
            af = n_alt_by_super[sc] / n_total_by_super[sc]
            freq_sum[sc] = freq_sum.get(sc, 0.0) + af
            freq_n[sc] = freq_n.get(sc, 0) + 1

print(f"Sites processed: {n_sites_processed}", file=sys.stderr)
print("=== Mean allele frequency of YH166's private-het alt alleles, by superclade ===")
print("(higher = that superclade more often already carries the same alt allele YH166 is heterozygous for)")
for sc in sorted(freq_sum, key=lambda x: -freq_sum[x] / freq_n[x]):
    mean_af = freq_sum[sc] / freq_n[sc]
    print(f"  {str(sc):24s}  mean_alt_freq={mean_af:.4f}  (n_sites={freq_n[sc]})")

print("\nDONE", file=sys.stderr)
