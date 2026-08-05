#!/bin/bash
# Joint multi-sample variant calling for one reference contig (chromosome-sharded
# to parallelize across the ~8 CBS 6340 chromosomes rather than doing all 145
# samples x whole genome in a single pass).
#
# Usage: 04_joint_call_shard.sh <contig_name>
set -euo pipefail

CONTIG="$1"
WORKDIR=/N/scratch/bochman/lachancea_pop
REF="$WORKDIR/ref/CBS6340.fna"
BAMLIST="$WORKDIR/pubpanel_bamlist.txt"
OUTDIR="$WORKDIR/joint_calls"
mkdir -p "$OUTDIR"

THREADS="${SLURM_CPUS_PER_TASK:-4}"

OUT="$OUTDIR/joint.${CONTIG}.vcf.gz"
if [ -s "$OUT" ]; then
  echo "[$CONTIG] SKIP: already called"
  exit 0
fi

echo "[$CONTIG] mpileup + call..."
bcftools mpileup -f "$REF" -r "$CONTIG" -b "$BAMLIST" \
  --threads "$THREADS" \
  -a FORMAT/AD,FORMAT/DP,INFO/AD,FORMAT/SP -Ou \
  | bcftools call -mv --threads "$THREADS" -Oz -o "$OUT"

bcftools index -t "$OUT"
echo "[$CONTIG] DONE"
