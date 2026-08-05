#!/bin/bash
# Run ADMIXTURE in supervised mode: ancestry proportions for our 3 strains are
# estimated against the 6 FIXED, already-known populations (from Table S1),
# not re-discovered from scratch. ADMIXTURE must be run from the directory
# containing combined.bed/.bim/.fam/.pop (it expects the .pop file alongside
# the .bed, matched by basename).
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate popgen

WORKDIR=/N/scratch/bochman/lachancea_pop
cd "$WORKDIR/placement"

THREADS="${SLURM_CPUS_PER_TASK:-8}"

admixture --supervised -j"$THREADS" combined.bed 6 | tee admixture_run.log

echo ""
echo "=== IMPORTANT: verifying the .Q column order actually matches our 1-6 cluster"
echo "    codes before trusting any of this - do not assume, check ==="
python3 << 'PYEOF'
CLUSTER_NAME = {
    "1": "Asia", "2": "Americas", "3": "Canada-trees",
    "4": "Europe/Domestic-1", "5": "Europe/Domestic-2", "6": "Europe-Mix",
}

fam_ids = [line.split()[1] for line in open("combined.fam")]
pop_labels = [line.strip() for line in open("combined.pop")]
q = [line.split() for line in open("combined.6.Q")]

assert len(fam_ids) == len(pop_labels) == len(q), "fam/pop/Q line counts don't match - stop"

# For each known cluster code, check that KNOWN samples with that label show
# their ancestry overwhelmingly in one consistent Q column. If column N
# consistently lights up for all samples labeled "N", the column order matches
# the label order as expected. If not, STOP - do not interpret placement results
# until this is resolved.
import collections
best_col_by_label = collections.defaultdict(collections.Counter)
for fid, label, qrow in zip(fam_ids, pop_labels, q):
    if label == "-":
        continue
    qvals = [float(x) for x in qrow]
    best_col = qvals.index(max(qvals)) + 1  # 1-indexed to match label convention
    best_col_by_label[label][best_col] += 1

print("For each known label, which Q column most samples with that label peak in:")
mapping_ok = True
for label in sorted(best_col_by_label):
    counts = best_col_by_label[label]
    total = sum(counts.values())
    top_col, top_n = counts.most_common(1)[0]
    consistent = "OK" if str(top_col) == label else "MISMATCH"
    if consistent == "MISMATCH":
        mapping_ok = False
    print(f"  label {label} ({CLUSTER_NAME[label]}): column {top_col} in {top_n}/{total} samples [{consistent}]")

if not mapping_ok:
    print("\nSTOP: Q column order does not cleanly match our 1-6 label convention.")
    print("Do not interpret placement results below until this is sorted out -")
    print("the column-to-cluster mapping must be determined empirically from")
    print("this table, not assumed from the label numbers.")
else:
    print("\nColumn order matches label convention as expected. Proceeding to report our strains:")
    print("")
    for fid, label, qrow in zip(fam_ids, pop_labels, q):
        if label == "-" and fid in ("YH26", "YH72", "YH140"):
            qvals = [float(x) for x in qrow]
            print(f"{fid}:")
            for i, v in enumerate(qvals, start=1):
                print(f"    {CLUSTER_NAME[str(i)]:20s} {v:.4f}")
PYEOF
