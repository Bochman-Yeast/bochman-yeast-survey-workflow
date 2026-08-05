#!/bin/bash
# Same logic as 10_make_plink_and_popfile.sh, applied to the Santos-VCF-based
# merge instead of our reconstruction. Uses popgen (not yeast-id) for plink -
# confirmed via job log during Walter Center consolidation that plink 1.9
# actually lives in popgen on this system.
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate popgen
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1

WORKDIR=/N/scratch/bochman/lachancea_pop
OUTDIR="$WORKDIR/santos_placement"
cd "$OUTDIR"

echo "=== VCF -> PLINK binary ==="
plink --vcf merged_for_placement.vcf.gz \
  --allow-extra-chr --geno 0.1 --maf 0.01 \
  --make-bed --out combined

echo ""
echo "=== Sites remaining after filtering ==="
wc -l combined.bim

echo ""
echo "=== Building population label file from Table S1 genocluster assignments ==="
python3 << 'PYEOF'
import csv

CLUSTER_CODE = {
    "Asia": "1",
    "Americas": "2",
    "Canada-trees": "3",
    "Europe/Domestic-1": "4",
    "Europe/Domestic-2": "5",
    "Europe-Mix": "6",
}
OUR_STRAINS = {"YH26", "YH72", "YH140"}

run_to_cluster = {}
with open("../download_manifest.tsv") as f:
    for row in csv.DictReader(f, delimiter="\t"):
        run_to_cluster[row["run_accession"]] = row["genocluster"]

pop_lines = []
unmatched = []
with open("combined.fam") as f:
    for line in f:
        iid = line.split()[1]
        if iid in OUR_STRAINS:
            pop_lines.append("-")
        elif iid in run_to_cluster:
            cluster = run_to_cluster[iid]
            if cluster in CLUSTER_CODE:
                pop_lines.append(CLUSTER_CODE[cluster])
            else:
                pop_lines.append("-")
                unmatched.append((iid, "blank genocluster in Table S1"))
        else:
            pop_lines.append("-")
            unmatched.append((iid, "not found in download_manifest.tsv at all"))

with open("combined.pop", "w") as f:
    f.write("\n".join(pop_lines) + "\n")

print(f"Wrote {len(pop_lines)} lines to combined.pop")
print(f"Known-label samples: {sum(1 for x in pop_lines if x != '-')}")
print(f"Unknown ('-') samples: {sum(1 for x in pop_lines if x == '-')} "
      f"(expect 3 for our strains, plus any Table S1 gaps below)")
if unmatched:
    print(f"\nFlagged as unknown for reasons other than being our own strains ({len(unmatched)}):")
    for iid, reason in unmatched:
        print(f"  {iid}: {reason}")
PYEOF

echo ""
echo "=== Cluster code key (for interpreting ADMIXTURE .Q columns later) ==="
echo "1=Asia 2=Americas 3=Canada-trees 4=Europe/Domestic-1 5=Europe/Domestic-2 6=Europe-Mix"

echo ""
echo "=== Fix chromosome codes for ADMIXTURE (integer-only, same fix as before) ==="
awk 'NR==FNR{map[$1]=FNR;next}{$1=map[$1];print}' OFS='\t' "$WORKDIR/ref/contigs.txt" combined.bim > combined.bim.fixed
cp combined.bim combined.bim.orig
mv combined.bim.fixed combined.bim
echo "Done - combined.bim.orig backed up, combined.bim now has integer chromosome codes"
