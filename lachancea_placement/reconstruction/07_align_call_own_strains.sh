#!/bin/bash
# Align our 3 strains' ONT reads against CBS 6340 (minimap2, NOT the Flye consensus
# assemblies - we want real read-level diploid genotype calls via Clair3, comparable
# in structure to the population panel's GATK diploid calls, not a haploid-consensus
# comparison). YH140 gets an extra filtering step to keep only reads that actually
# align to this (Lachancea-only) reference, since its filtered.fastq.gz is still the
# full mixed Lachancea+Torulaspora read set.
#
# CLAIR3_MODEL must be set after running 06_check_clair3_models.sh and confirming
# which bundled model matches the actual basecaller used - do not run this with a
# guessed model name.
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id

WORKDIR=/N/scratch/bochman/lachancea_pop
REF="$WORKDIR/ref/CBS6340.fna"
OUTDIR="$WORKDIR/aligned/ours"
CALLDIR="$WORKDIR/calls/ours"
mkdir -p "$OUTDIR" "$CALLDIR"

THREADS="${SLURM_CPUS_PER_TASK:-16}"
CLAIR3_MODEL="${CLAIR3_MODEL:?Set CLAIR3_MODEL after running 06_check_clair3_models.sh}"

align_and_call() {
  local strain="$1" reads="$2"
  local bam="$OUTDIR/${strain}.bam"

  echo "[$strain] aligning..."
  minimap2 -ax map-ont -t "$THREADS" "$REF" "$reads" \
    | samtools sort -@ "$THREADS" -o "$bam" -
  samtools index "$bam"
  samtools flagstat "$bam" > "$WORKDIR/logs/${strain}_flagstat.txt"

  echo "[$strain] Clair3 (diploid, ont)..."
  run_clair3.sh \
    --bam_fn="$bam" \
    --ref_fn="$REF" \
    --threads="$THREADS" \
    --platform=ont \
    --model_path="$CLAIR3_MODEL" \
    --include_all_ctgs \
    --sample_name="$strain" \
    --output="$CALLDIR/$strain"
}

# --- YH26 and YH72: clean single-species ONT reads, use directly ---
align_and_call YH26 /N/scratch/bochman/yeast_id/results/YH26/filtered/YH26.filt.fastq.gz
align_and_call YH72 /N/scratch/bochman/yeast_id/results/YH72/filtered/YH72.filt.fastq.gz

# --- YH140: mixed culture - align ALL filtered reads to this Lachancea-only reference
#     first, then keep only primary+mapped alignments (Torulaspora reads should fail
#     to align meaningfully against a Lachancea-only reference; this is a cleaner,
#     more direct filter than going through the earlier contig-bin classification) ---
echo "[YH140] aligning full mixed read set to CBS6340..."
minimap2 -ax map-ont -t "$THREADS" "$REF" \
  /N/scratch/bochman/yeast_id/results/YH140/filtered/YH140.filt.fastq.gz \
  | samtools sort -@ "$THREADS" -o "$OUTDIR/YH140_allreads.bam" -
samtools index "$OUTDIR/YH140_allreads.bam"

echo "[YH140] filtering to primary, mapped, MAPQ>=20 alignments only..."
samtools view -@ "$THREADS" -b -q 20 -F 0x904 \
  "$OUTDIR/YH140_allreads.bam" > "$OUTDIR/YH140.bam"
samtools index "$OUTDIR/YH140.bam"
samtools flagstat "$OUTDIR/YH140.bam" > "$WORKDIR/logs/YH140_filtered_flagstat.txt"

echo "[YH140] sanity check - compare read count here against the"
echo "        read_species_fraction.tsv Lachancea count from the mixed_investigation"
echo "        (expect roughly ~61133 reads, not the full ~77464) before trusting this:"
samtools view -c "$OUTDIR/YH140.bam"

echo "[YH140] Clair3 (diploid, ont)..."
run_clair3.sh \
  --bam_fn="$OUTDIR/YH140.bam" \
  --ref_fn="$REF" \
  --threads="$THREADS" \
  --platform=ont \
  --model_path="$CLAIR3_MODEL" \
  --include_all_ctgs \
  --sample_name=YH140 \
  --output="$CALLDIR/YH140"
