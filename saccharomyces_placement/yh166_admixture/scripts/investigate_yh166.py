#!/usr/bin/env python3
import sys
from collections import Counter
import pandas as pd
from Bio import Phylo

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"
TARGET = "YH166"

df = pd.read_excel(f"{PROJ}/metadata/supp/Table_S1_G3-2024-405400.xlsx", sheet_name="TableS1", header=2)
df = df.dropna(subset=["StandardizedName"])
meta = df.set_index("StandardizedName").to_dict(orient="index")

tree = Phylo.read(f"{PROJ}/placement/combined_tree.nwk", "newick")
path = tree.get_path(TARGET)

for level in range(-2, -8, -1):
    if len(path) < abs(level):
        break
    parent = path[level]
    terms = [t.name for t in parent.get_terminals() if t.name != TARGET]
    support = parent.confidence
    clades = Counter(meta[t]["Clade"] if t in meta else "NOT_IN_PANEL" for t in terms)
    superclades = Counter(meta[t]["SuperClade"] if t in meta else "NOT_IN_PANEL" for t in terms)
    print(f"\nLevel {level}: {len(terms)} other tip(s), support={support}")
    print(f"  Clade breakdown: {clades.most_common(8)}")
    print(f"  SuperClade breakdown: {superclades.most_common(8)}")

print(f"\n=== Origin info for immediate/near neighbors ===")
parent = path[-3] if len(path) >= 3 else path[-2]
terms = [t.name for t in parent.get_terminals() if t.name != TARGET]
for t in terms:
    if t in meta:
        m = meta[t]
        print(f"  {t}: Clade={m.get('Clade')}, SuperClade={m.get('SuperClade')}, "
              f"GeographicOrigin={m.get('GeographicOrigin')}, EcoOrigin={m.get('EcoOrigin')}, "
              f"Country={m.get('Country')}, Zygosity={m.get('Zygosity')}, Ploidy={m.get('Ploidy')}")
