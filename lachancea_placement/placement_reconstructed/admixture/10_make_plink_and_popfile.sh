#!/bin/bash
# Convert the merged VCF to PLINK binary format, then build the .pop file
# ADMIXTURE's --supervised mode needs: one line per sample IN THE SAME ORDER
# AS THE .fam FILE, giving either the known population code (1-6, mapped
# below to the paper's six clusters) or "-" for samples to be inferred
# (our 3 strains). Reads the .fam file's actual sample order rather than
# assuming one, since plink/bcftools merge order isn't something to guess at.
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id

WORKDIR=/N/scratch/bochman/lachancea_pop
OUTDIR="$WORKDIR/placement"
cd "$OUTDIR"

echo "=== VCF -> PLINK binary ==="
echo "--allow-extra-chr: reference contigs are NC_0130xx.1, not human-style"
echo "--geno 0.1: drop sites with >10% missing genotypes across all 148 samples"
echo "--maf 0.01: drop ultra-rare/singleton sites (standard for ADMIXTURE input)"
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

# run_accession -> genocluster, from the manifest built back when we set up downloads
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
                # 2 strains in Table S1 have no genocluster listed - treat as unknown
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
