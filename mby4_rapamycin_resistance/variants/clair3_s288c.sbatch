#!/bin/bash
#SBATCH --job-name=MBY4_clair3_s288c
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/variants/clair3_s288c_%j.log

# STATUS: untested template. Basecaller confirmed from read headers (2026-08-09):
# dna_r10.4.1_e8.2_400bps_sup@v4.3.0 (see ../NOTES.md). MODEL_PATH below is a search-derived
# guess (r1041_e82_400bps_sup_v430) NOT independently confirmed against this Quartz install
# -- the find command below checks for it and fails loudly if absent rather than silently
# running with a wrong/default model. run_clair3.sh's exact CLI flags (esp. --platform,
# --model_path) should also be checked against the installed Clair3 version's own --help
# before running; do not assume flag names/defaults.
#
# Uses its OWN conda env (mby4_rapamycin_clair3, see ../environment_clair3.yml), separate
# from the main mby4_rapamycin env used by every other script in this package -- Clair3's
# pinned pytorch/tensorflow stack is a common source of solver conflicts if bundled together.

source ~/.bashrc
conda activate mby4_rapamycin_clair3

run_clair3.sh --version 2>&1 | head -5 || true

REF=/N/scratch/bochman/mby4_rapamycin/reference/S288c_R64.fna
BAM=/N/scratch/bochman/mby4_rapamycin/mapping/MBY4_vs_S288c.sorted.bam
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
  --output=/N/scratch/bochman/mby4_rapamycin/variants/MBY4_vs_S288c_clair3

echo "--- variant count ---"
zcat /N/scratch/bochman/mby4_rapamycin/variants/MBY4_vs_S288c_clair3/merge_output.vcf.gz | grep -vc '^#'
