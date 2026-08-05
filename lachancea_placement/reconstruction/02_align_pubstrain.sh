#!/bin/bash
# Align one published-panel strain (Illumina PE) against CBS 6340 with bwa-mem2,
# then fixmate/sort/markdup with samtools. Sample ID = run_accession throughout
# (strain names have spaces/slashes that break filenames and @RG tags -
# strain/cluster/origin metadata stays in download_manifest.tsv, joined back in later).
#
# Usage: 02_align_pubstrain.sh <run_accession> <fastq_r1> <fastq_r2>
set -euo pipefail

RUN="$1"
R1="$2"
R2="$3"

WORKDIR=/N/scratch/bochman/lachancea_pop
REF="$WORKDIR/ref/CBS6340.fna"
OUTDIR="$WORKDIR/aligned/pubpanel"
LOGDIR="$WORKDIR/logs/align"
mkdir -p "$OUTDIR" "$LOGDIR"

THREADS="${SLURM_CPUS_PER_TASK:-8}"

DEDUP_BAM="$OUTDIR/${RUN}.dedup.bam"
if [ -s "$DEDUP_BAM" ] && [ -s "${DEDUP_BAM}.bai" ]; then
  echo "[$RUN] SKIP: dedup BAM already exists"
  exit 0
fi

echo "[$RUN] Aligning..."
bwa-mem2 mem -t "$THREADS" \
  -R "@RG\tID:${RUN}\tSM:${RUN}\tPL:ILLUMINA" \
  "$REF" "$R1" "$R2" \
  | samtools fixmate -m -@ "$THREADS" - - \
  | samtools sort -@ "$THREADS" -o "$OUTDIR/${RUN}.sorted.bam" -

echo "[$RUN] Marking duplicates..."
samtools markdup -@ "$THREADS" "$OUTDIR/${RUN}.sorted.bam" "$DEDUP_BAM"
samtools index "$DEDUP_BAM"

echo "[$RUN] flagstat..."
samtools flagstat "$DEDUP_BAM" > "$LOGDIR/${RUN}.flagstat.txt"

rm -f "$OUTDIR/${RUN}.sorted.bam"
echo "[$RUN] DONE"
