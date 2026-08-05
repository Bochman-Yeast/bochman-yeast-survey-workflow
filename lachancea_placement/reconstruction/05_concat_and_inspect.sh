#!/bin/bash
# Concatenate per-contig joint VCFs, normalize (split multiallelics, left-align indels),
# then print the available INFO/FORMAT annotation fields so we can pick real filter
# thresholds instead of guessing GATK-analog field names blindly.
set -euo pipefail

WORKDIR=/N/scratch/bochman/lachancea_pop
REF="$WORKDIR/ref/CBS6340.fna"
OUTDIR="$WORKDIR/joint_calls"
CONTIGLIST="$WORKDIR/ref/contigs.txt"

cd "$OUTDIR"

VCFLIST=()
while read -r contig; do
  VCFLIST+=("joint.${contig}.vcf.gz")
done < "$CONTIGLIST"

echo "=== Concatenating ${#VCFLIST[@]} contig VCFs ==="
bcftools concat -a "${VCFLIST[@]}" -Oz -o joint_raw.vcf.gz
bcftools index -t joint_raw.vcf.gz

echo "=== Normalizing (split multiallelics, left-align) ==="
bcftools norm -f "$REF" -m -any joint_raw.vcf.gz -Oz -o joint_norm.vcf.gz
bcftools index -t joint_norm.vcf.gz

echo ""
echo "=== Basic counts ==="
echo -n "Raw records: "; bcftools view -H joint_raw.vcf.gz | wc -l
echo -n "Normalized records: "; bcftools view -H joint_norm.vcf.gz | wc -l
echo -n "Samples: "; bcftools query -l joint_norm.vcf.gz | wc -l

echo ""
echo "=== Available INFO fields (for choosing real filter thresholds - do NOT assume"
echo "    GATK field names like QD/SOR/FS carry over; bcftools uses different ones) ==="
bcftools view -h joint_norm.vcf.gz | grep '^##INFO'

echo ""
echo "=== Available FORMAT fields ==="
bcftools view -h joint_norm.vcf.gz | grep '^##FORMAT'

echo ""
echo "=== Spot-check: first 3 variant records in full, to see real annotation values ==="
bcftools view joint_norm.vcf.gz | grep -v '^##' | head -4
