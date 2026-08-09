#!/bin/bash
#SBATCH --job-name=MBY4_clair3_w303
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/variants/clair3_w303_%j.log

# STATUS: untested template. W303 accession resolved (../reference/PROVENANCE.md —
# GCA_965282845.1, downloaded and staged). Basecaller confirmed from read headers
# (2026-08-09): dna_r10.4.1_e8.2_400bps_sup@v4.3.0 (see ../NOTES.md). See
# clair3_s288c.sbatch's header comment re: MODEL_PATH verification.

source ~/.bashrc
conda activate mby4_rapamycin

run_clair3.sh --version 2>&1 | head -5 || true

REF=/N/scratch/bochman/mby4_rapamycin/reference/W303.fna
BAM=/N/scratch/bochman/mby4_rapamycin/mapping/MBY4_vs_W303.sorted.bam
MODEL_PATH=$(find "$CONDA_PREFIX" -iname "*r1041_e82_400bps_sup*" -type d 2>/dev/null | head -1)
if [[ -z "$MODEL_PATH" ]]; then
  echo "ERROR: no r1041_e82_400bps_sup Clair3 model found under \$CONDA_PREFIX. Verify the" >&2
  echo "correct model name/location (e.g. via nanoporetech/rerio) and set MODEL_PATH manually." >&2
  exit 1
fi
echo "Using Clair3 model: $MODEL_PATH"

run_clair3.sh \
  --bam_fn=$BAM \
  --ref_fn=$REF \
  --threads=16 \
  --platform=ont \
  --model_path=$MODEL_PATH \
  --output=/N/scratch/bochman/mby4_rapamycin/variants/MBY4_vs_W303_clair3

echo "--- variant count ---"
zcat /N/scratch/bochman/mby4_rapamycin/variants/MBY4_vs_W303_clair3/merge_output.vcf.gz | grep -vc '^#'
