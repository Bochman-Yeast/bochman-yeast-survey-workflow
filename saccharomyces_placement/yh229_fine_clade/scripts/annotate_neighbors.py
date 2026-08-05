#!/usr/bin/env python3
import sys
from collections import Counter
import pandas as pd
from Bio import Phylo

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"
TARGETS = ["YH123", "YH166", "YH196", "YH229", "DoF1"]

df = pd.read_excel(f"{PROJ}/metadata/supp/Table_S1_G3-2024-405400.xlsx", sheet_name="TableS1", header=2)
df = df.dropna(subset=["StandardizedName"])
meta = df.set_index("StandardizedName").to_dict(orient="index")
print(f"Loaded metadata for {len(meta)} panel isolates", file=sys.stderr)

tree = Phylo.read(f"{PROJ}/placement/combined_tree.nwk", "newick")
print(f"Tree loaded: {tree.count_terminals()} tips", file=sys.stderr)

for target in TARGETS:
    print(f"\n=== {target} ===")
    path = tree.get_path(target)
    if not path:
        print("  NOT FOUND IN TREE")
        continue
    for level, label in [(-2, "immediate sister clade"), (-3, "grandparent level")]:
        if len(path) < abs(level):
            continue
        parent = path[level]
        terms = [t.name for t in parent.get_terminals() if t.name not in TARGETS]
        support = parent.confidence
        clades = Counter(meta[t]["Clade"] for t in terms if t in meta)
        superclades = Counter(meta[t]["SuperClade"] for t in terms if t in meta)
        print(f"  {label}: {len(terms)} other tip(s), support={support}")
        print(f"    Clade breakdown: {clades.most_common(5)}")
        print(f"    SuperClade breakdown: {superclades.most_common(5)}")
        example_names = [f"{t} ({meta[t]['Clade']})" for t in terms[:8] if t in meta]
        print(f"    Examples: {example_names}")

print("\nDONE", file=sys.stderr)
