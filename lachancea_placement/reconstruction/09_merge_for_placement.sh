#!/bin/bash
# Merge our 3 strains' Clair3 calls with the 145-strain joint-called population
# panel (fallback path - only used if we never get Santos's authoritative VCF).
# Normalizes each of our own VCFs to biallelic-split first (population panel
# already went through this in 05_concat_and_inspect.sh) so bcftools merge
# doesn't need to re-decide how to combine multiallelic sites across sources.
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id

WORKDIR=/N/scratch/bochman/lachancea_pop
REF="$WORKDIR/ref/CBS6340.fna"
OUTDIR="$WORKDIR/placement"
mkdir -p "$OUTDIR/norm_ours"

echo "=== Normalizing our 3 strains' Clair3 VCFs ==="
for s in YH26 YH72 YH140; do
  in="$WORKDIR/calls/ours/$s/merge_output.vcf.gz"
  out="$OUTDIR/norm_ours/${s}.norm.vcf.gz"
  bcftools norm -f "$REF" -m -any "$in" -Oz -o "$out"
  bcftools index -t "$out"
  echo "  $s: $(bcftools view -H "$out" | wc -l) records after normalization"
done

echo ""
echo "=== Merging with the population panel ==="
POP_VCF="$WORKDIR/joint_calls/joint_norm.vcf.gz"
if [ ! -s "$POP_VCF" ]; then
  echo "ERROR: $POP_VCF not found - the population panel joint-calling"
  echo "(scripts 02-05, 08) needs to have completed first. This script is"
  echo "the fallback path and depends on that having been run."
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
echo "Sample list:"
bcftools query -l "$OUTDIR/merged_for_placement.vcf.gz"
