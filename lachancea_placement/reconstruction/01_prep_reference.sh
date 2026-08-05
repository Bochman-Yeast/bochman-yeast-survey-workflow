#!/bin/bash
# Index CBS 6340 reference for bwa-mem2 + verify contig set (esp. mitochondrial presence).
source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id
set -euo pipefail

REF=/N/scratch/bochman/yeast_id/refs/Lachancea_thermotolerans/genome.fna
WORKDIR=/N/scratch/bochman/lachancea_pop
mkdir -p "$WORKDIR/ref"

# Work from a copy in our own project dir rather than mutating yeast_id/refs in place
cp -n "$REF" "$WORKDIR/ref/CBS6340.fna"
cd "$WORKDIR/ref"

samtools faidx CBS6340.fna
bwa-mem2 index CBS6340.fna

echo "=== Contigs in reference (name, length) ==="
cat CBS6340.fna.fai | cut -f1,2

echo ""
echo "=== Contig count ==="
wc -l < CBS6340.fna.fai

echo ""
echo "=== CHECK: does this look like nuclear-only (8 chromosomes, no mito)? ==="
echo "L. thermotolerans CBS 6340 nuclear genome is reported as 8 chromosomes."
echo "If the count above is not 8, or if a contig is unexpectedly small/circular-looking"
echo "(mitochondrial genomes are typically much smaller, ~20-50kb, than nuclear chromosomes),"
echo "STOP and flag it - this determines whether mito reads need special handling"
echo "for the YH140 mixed-culture alignment step (see prior mis-mapping-sink lesson)."
