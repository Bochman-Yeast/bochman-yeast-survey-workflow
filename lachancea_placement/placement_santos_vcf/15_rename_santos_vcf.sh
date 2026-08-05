#!/bin/bash
# Rename Santos's VCF to match our conventions: contigs LATH0A-H -> the same
# NC_0130xx.1 accessions we used (identical chromosomes, confirmed by exact
# length match), and samples seq_code -> run_accession (via
# sample_rename_map.txt from 14_map_santos_samples.py). This makes the
# result a drop-in replacement for our own joint_filtered.vcf.gz in every
# downstream script - no other script needs to change.
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1

WORKDIR=/N/scratch/bochman/lachancea_pop
SDIR="$WORKDIR/santos_vcf"
IN="$SDIR/145str_snps_filtered.bgz.vcf.gz"

echo "=== contig rename map (LATH0A-H -> NC_0130xx.1, confirmed identical by length) ==="
cat > "$SDIR/chr_rename_map.txt" << 'CHRMAP'
LATH0A NC_013077.1
LATH0B NC_013078.1
LATH0C NC_013079.1
LATH0D NC_013080.1
LATH0E NC_013081.1
LATH0F NC_013082.1
LATH0G NC_013083.1
LATH0H NC_013084.1
CHRMAP
cat "$SDIR/chr_rename_map.txt"

echo ""
echo "=== step 1: rename contigs ==="
bcftools annotate --rename-chrs "$SDIR/chr_rename_map.txt" \
  -Oz -o "$SDIR/santos_chrrenamed.vcf.gz" "$IN"
bcftools index -t "$SDIR/santos_chrrenamed.vcf.gz"

echo ""
echo "=== step 2: rename samples (order-preserving, from sample_rename_map.txt) ==="
cut -f2 "$SDIR/sample_rename_map.txt" > "$SDIR/new_sample_names.txt"
wc -l "$SDIR/new_sample_names.txt"
bcftools reheader -s "$SDIR/new_sample_names.txt" \
  -o "$SDIR/santos_renamed.vcf.gz" "$SDIR/santos_chrrenamed.vcf.gz"
bcftools index -t "$SDIR/santos_renamed.vcf.gz"

echo ""
echo "=== verify: sample names now match our run_accession convention ==="
bcftools query -l "$SDIR/santos_renamed.vcf.gz" | head -5
echo "..."
echo -n "Total samples: "; bcftools query -l "$SDIR/santos_renamed.vcf.gz" | wc -l

echo ""
echo "=== verify: contig names now match our reference ==="
bcftools view -h "$SDIR/santos_renamed.vcf.gz" | grep '^##contig'

echo ""
echo "=== verify: site count unchanged through both renames ==="
echo -n "Original: "; bcftools view -H "$IN" | wc -l
echo -n "Final:    "; bcftools view -H "$SDIR/santos_renamed.vcf.gz" | wc -l
