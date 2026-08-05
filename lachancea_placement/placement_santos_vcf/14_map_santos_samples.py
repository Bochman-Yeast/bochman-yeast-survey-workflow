#!/usr/bin/env python3
# Build a Santos-VCF-sample-name -> run_accession mapping, so the real filtered
# VCF can be reheadered to match our existing run_accession-based convention
# (download_manifest.tsv, genocluster popfile logic, etc.) without changing
# any downstream script.
#
# Strategy: try a direct match against download_manifest.tsv's own seq_code
# column first (it already carries seq_code independently of S1_strains.tsv).
# Only fall back to S1_strains.tsv's ucm_code -> seq_code chain for whatever
# doesn't resolve directly - don't assume the chain is needed until the
# direct path actually fails for a given sample.
import csv
import subprocess
import sys

WORKDIR = "/N/scratch/bochman/lachancea_pop"

# --- load download_manifest.tsv: seq_code -> run_accession (direct) ---
seqcode_to_run = {}
strain_to_run = {}
with open(f"{WORKDIR}/download_manifest.tsv") as f:
    for row in csv.DictReader(f, delimiter="\t"):
        if row["seq_code"]:
            seqcode_to_run[row["seq_code"]] = row["run_accession"]
        if row["strain"]:
            strain_to_run[row["strain"]] = row["run_accession"]

# --- load S1_strains.tsv: ucm_code -> seq_code, strain -> seq_code (fallback path) ---
ucmcode_to_seqcode = {}
strain_to_seqcode = {}
with open(f"{WORKDIR}/santos_vcf/S1_strains.tsv") as f:
    for row in csv.DictReader(f, delimiter="\t"):
        if row["ucm_code"]:
            ucmcode_to_seqcode[row["ucm_code"]] = row["seq_code"]
        if row["strain"]:
            strain_to_seqcode[row["strain"]] = row["seq_code"]

# --- get the actual 145 sample names from Santos's VCF ---
vcf = f"{WORKDIR}/santos_vcf/145str_snps_filtered.bgz.vcf.gz"
result = subprocess.run(["bcftools", "query", "-l", vcf], capture_output=True, text=True, check=True)
vcf_samples = [s for s in result.stdout.strip().split("\n") if s]

print(f"VCF sample count: {len(vcf_samples)}")

mapping = {}
unresolved = []
resolution_method = {}

for s in vcf_samples:
    # path 1: direct seq_code match
    if s in seqcode_to_run:
        mapping[s] = seqcode_to_run[s]
        resolution_method[s] = "direct seq_code"
        continue
    # path 2: this name is actually a ucm_code -> resolve to seq_code -> run_accession
    if s in ucmcode_to_seqcode:
        sc = ucmcode_to_seqcode[s]
        if sc in seqcode_to_run:
            mapping[s] = seqcode_to_run[sc]
            resolution_method[s] = f"ucm_code->seq_code({sc})"
            continue
    unresolved.append(s)

print(f"Resolved directly via seq_code: {sum(1 for m in resolution_method.values() if m == 'direct seq_code')}")
print(f"Resolved via ucm_code->seq_code chain: {sum(1 for m in resolution_method.values() if m != 'direct seq_code')}")
print(f"Unresolved: {len(unresolved)}")

if unresolved:
    print("\n=== UNRESOLVED SAMPLES (need manual investigation) ===")
    for s in unresolved:
        print(f"  {s}")
    print("\nSTOP: do not proceed to reheader until every sample resolves -")
    print("a silent drop or mismatch here would corrupt the merge.")
    sys.exit(1)

# --- check for duplicate run_accession targets (would indicate an ambiguous mapping) ---
from collections import Counter
run_counts = Counter(mapping.values())
dupes = {k: v for k, v in run_counts.items() if v > 1}
if dupes:
    print(f"\nSTOP: {len(dupes)} run_accession value(s) claimed by multiple VCF samples:")
    for run_acc, n in dupes.items():
        claimants = [s for s, r in mapping.items() if r == run_acc]
        print(f"  {run_acc} <- {claimants}")
    sys.exit(1)

print(f"\nAll {len(vcf_samples)} samples resolved uniquely. Writing rename map.")
with open(f"{WORKDIR}/santos_vcf/sample_rename_map.txt", "w") as f:
    for s in vcf_samples:
        f.write(f"{s}\t{mapping[s]}\n")

print(f"Wrote {WORKDIR}/santos_vcf/sample_rename_map.txt")
print("\nFirst 5 lines:")
for s in vcf_samples[:5]:
    print(f"  {s}\t{mapping[s]}\t[{resolution_method[s]}]")
