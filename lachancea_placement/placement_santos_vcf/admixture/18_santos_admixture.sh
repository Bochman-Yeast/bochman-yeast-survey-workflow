#!/bin/bash
# Same supervised ADMIXTURE run as 11_run_admixture_supervised.sh, against
# the Santos-VCF-based combined.bed/bim/fam/pop in santos_placement/.
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate popgen
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1

WORKDIR=/N/scratch/bochman/lachancea_pop
cd "$WORKDIR/santos_placement"

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

import collections
best_col_by_label = collections.defaultdict(collections.Counter)
for fid, label, qrow in zip(fam_ids, pop_labels, q):
    if label == "-":
        continue
    qvals = [float(x) for x in qrow]
    best_col = qvals.index(max(qvals)) + 1
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
    print("Do not interpret placement results below until this is sorted out.")
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
