#!/usr/bin/env python3
import sys, gzip
import pandas as pd

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"
SAMPLES = ["YH123", "YH166", "YH196", "YH229", "DoF1"]
GENOME_LEN = 12071326

df = pd.read_excel(f"{PROJ}/metadata/supp/Table_S1_G3-2024-405400.xlsx", sheet_name="TableS1", header=2)
df = df.dropna(subset=["StandardizedName"])
print("=== Panel-wide heterozygosity by SuperClade ===")
print(df.groupby("SuperClade")["Heterozygosity"].agg(["count","mean","median","std"]).to_string())
print("\n=== Panel-wide Zygosity counts ===")
print(df["Zygosity"].value_counts().to_string())
print("\n=== Panel-wide Ploidy counts ===")
print(df["Ploidy"].value_counts().to_string())

print("\n=== Our isolates ===")
for s in SAMPLES:
    path = f"{PROJ}/calls/{s}/merge_output.vcf.gz"
    n_het = n_homalt = n_total = 0
    with gzip.open(path, "rt") as f:
        for line in f:
            if line.startswith("#"):
                continue
            parts = line.rstrip("\n").split("\t")
            fmt = parts[8].split(":")
            gt = parts[9].split(":")[fmt.index("GT")].replace("|", "/")
            alleles = gt.split("/")
            n_total += 1
            if len(set(alleles)) > 1:
                n_het += 1
            elif alleles[0] not in ("0", "."):
                n_homalt += 1
    het_rate = n_het / GENOME_LEN
    print(f"{s}: total_variants={n_total}  het={n_het}  hom_alt={n_homalt}  "
          f"HeterozygosityRate={het_rate:.6f}  (het/total_variant_ratio={n_het/n_total:.3f})")

print("\nDONE", file=sys.stderr)
