#!/usr/bin/env python3
import sys, zipfile, glob, os
import pandas as pd

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"
META_DIR = f"{PROJ}/metadata"
ZIP_PATH = f"{META_DIR}/jkae245_supplementary_data.zip"
SUPP_DIR = f"{META_DIR}/supp"

if not os.path.exists(ZIP_PATH):
    sys.exit(
        f"ERROR: {ZIP_PATH} not found.\n"
        "Download it manually via browser (Oxford's CDN blocks automated fetches) from:\n"
        "  https://academic.oup.com/g3journal/article/14/12/jkae245/7904545#supplementary-data\n"
        "then scp it here from your local machine:\n"
        f"  scp jkae245_supplementary_data.zip bochman@quartz.uits.iu.edu:{META_DIR}/"
    )

if not os.path.exists(SUPP_DIR) or not glob.glob(f"{SUPP_DIR}/Table_S1*.xlsx"):
    os.makedirs(SUPP_DIR, exist_ok=True)
    with zipfile.ZipFile(ZIP_PATH) as z:
        z.extractall(SUPP_DIR)
    print(f"Unzipped to {SUPP_DIR}", file=sys.stderr)

t1_path = glob.glob(f"{SUPP_DIR}/Table_S1*.xlsx")[0]
t2_path = glob.glob(f"{SUPP_DIR}/Table_S2*.xlsx")[0]

df1 = pd.read_excel(t1_path, sheet_name="TableS1", header=2)
df1 = df1.dropna(subset=["StandardizedName"])
df1.to_csv(f"{META_DIR}/panel_isolates.tsv", sep="\t", index=False)
print(f"Wrote {META_DIR}/panel_isolates.tsv  ({len(df1)} isolates, {len(df1.columns)} columns)", file=sys.stderr)

df2 = pd.read_excel(t2_path, sheet_name="TableS2", header=2)
df2 = df2.dropna(subset=["Name"])
df2.to_csv(f"{META_DIR}/clades.tsv", sep="\t", index=False)
print(f"Wrote {META_DIR}/clades.tsv  ({len(df2)} clades/superclades)", file=sys.stderr)

print("DONE", file=sys.stderr)
