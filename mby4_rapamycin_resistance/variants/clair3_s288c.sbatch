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

# STATUS: untested template. MODEL_PATH must be set to the Clair3 model matching MBY4's
# basecaller — see ../README.md open decision point 1. run_clair3.sh's exact CLI flags
# (esp. --platform, --model_path) should be checked against the installed Clair3 version's
# own --help before running; do not assume flag names/defaults.

source ~/.bashrc
conda activate mby4_rapamycin

run_clair3.sh --version 2>&1 | head -5 || true

REF=/N/scratch/bochman/mby4_rapamycin/reference/S288c_R64.fna
BAM=/N/scratch/bochman/mby4_rapamycin/mapping/MBY4_vs_S288c.sorted.bam
MODEL_PATH=/PATH/TO/CLAIR3/MODEL   # PLACEHOLDER — must match basecaller, e.g. r1041_e82_400bps_sup

run_clair3.sh \
  --bam_fn=$BAM \
  --ref_fn=$REF \
  --threads=16 \
  --platform=ont \
  --model_path=$MODEL_PATH \
  --output=/N/scratch/bochman/mby4_rapamycin/variants/MBY4_vs_S288c_clair3

echo "--- variant count ---"
zcat /N/scratch/bochman/mby4_rapamycin/variants/MBY4_vs_S288c_clair3/merge_output.vcf.gz | grep -vc '^#'
