#!/bin/bash
# Same merge logic as 09_merge_for_placement.sh, but against Santos's real,
# renamed, filtered VCF instead of our bcftools reconstruction - kept in a
# separate output directory (santos_placement/) so both results can be
# compared side by side rather than overwriting the reconstruction-based run.
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1

WORKDIR=/N/scratch/bochman/lachancea_pop
REF="$WORKDIR/ref/CBS6340.fna"
OUTDIR="$WORKDIR/santos_placement"
mkdir -p "$OUTDIR/norm_ours"

echo "=== Normalizing our 3 strains' Clair3 VCFs (same inputs as before) ==="
for s in YH26 YH72 YH140; do
  in="$WORKDIR/calls/ours/$s/merge_output.vcf.gz"
  out="$OUTDIR/norm_ours/${s}.norm.vcf.gz"
  bcftools norm -f "$REF" -m -any "$in" -Oz -o "$out"
  bcftools index -t "$out"
  echo "  $s: $(bcftools view -H "$out" | wc -l) records after normalization"
done

echo ""
echo "=== Merging with Santos's real, renamed, filtered VCF ==="
POP_VCF="$WORKDIR/santos_vcf/santos_renamed.vcf.gz"
if [ ! -s "$POP_VCF" ]; then
  echo "ERROR: $POP_VCF not found - run 15_rename_santos_vcf.sh first."
  exit 1
fi

bcftools merge -m none \
  "$POP_VCF" \
  "$OUTDIR/norm_ours/YH26.norm.vcf.gz" \
  "$OUTDIR/norm_ours/YH72.norm.vcf.gz" \
  "$OUTDIR/norm_ours/YH140.norm.vcf.gz" \
  -Oz -o "$OUTDIR/merged_for_placement.vcf.gz"
bcftools index -t "$OUTDIR/merged_for_placement.vcf.gz"

echo ""
echo "=== Merged VCF summary ==="
echo -n "Samples: "; bcftools query -l "$OUTDIR/merged_for_placement.vcf.gz" | wc -l
echo -n "Sites: "; bcftools view -H "$OUTDIR/merged_for_placement.vcf.gz" | wc -l
echo "Sample list (first 5 + our 3):"
bcftools query -l "$OUTDIR/merged_for_placement.vcf.gz" | head -5
bcftools query -l "$OUTDIR/merged_for_placement.vcf.gz" | grep -E "^YH(26|72|140)$"
