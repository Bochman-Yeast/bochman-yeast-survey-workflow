#!/usr/bin/env python3
import sys, gzip

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"
SAMPLES = ["YH123", "YH166", "YH196", "YH229", "DoF1"]

panel_sites = set()
with open(f"{PROJ}/placement/all_panel_sites.tsv") as f:
    for line in f:
        chrom, pos = line.strip().split("\t")
        panel_sites.add((chrom, int(pos)))
print(f"Panel catalog: {len(panel_sites)} SNP positions", file=sys.stderr)

for s in SAMPLES:
    path = f"{PROJ}/calls/{s}/merge_output.vcf.gz"
    n_snp = n_indel = n_private_snp = n_private_het = 0
    with gzip.open(path, "rt") as f:
        for line in f:
            if line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            chrom, pos, ref, alt = parts[0], int(parts[1]), parts[3], parts[4]
            if len(ref) != 1 or len(alt) != 1:
                n_indel += 1
                continue
            n_snp += 1
            if (chrom, pos) not in panel_sites:
                n_private_snp += 1
                fmt = parts[8].split(":")
                gt = parts[9].split(":")[fmt.index("GT")].replace("|", "/")
                if len(set(gt.split("/"))) > 1:
                    n_private_het += 1
    pct = 100 * n_private_snp / n_snp if n_snp else 0
    print(f"{s}: total_SNPs={n_snp}  indels={n_indel}  "
          f"private_SNPs(not in panel catalog)={n_private_snp} ({pct:.1f}%)  "
          f"of_which_heterozygous={n_private_het}")

print("DONE", file=sys.stderr)
