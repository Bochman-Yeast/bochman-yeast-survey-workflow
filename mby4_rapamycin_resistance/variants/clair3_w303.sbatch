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

# STATUS: untested template. DO NOT RUN until W303 accession is resolved
# (../reference/PROVENANCE.md). MODEL_PATH must match clair3_s288c.sbatch's choice.

source ~/.bashrc
conda activate mby4_rapamycin

run_clair3.sh --version 2>&1 | head -5 || true

REF=/N/scratch/bochman/mby4_rapamycin/reference/W303.fna   # PLACEHOLDER — path depends on accession resolution
BAM=/N/scratch/bochman/mby4_rapamycin/mapping/MBY4_vs_W303.sorted.bam
MODEL_PATH=/PATH/TO/CLAIR3/MODEL   # PLACEHOLDER — must match clair3_s288c.sbatch

run_clair3.sh \
  --bam_fn=$BAM \
  --ref_fn=$REF \
  --threads=16 \
  --platform=ont \
  --model_path=$MODEL_PATH \
  --output=/N/scratch/bochman/mby4_rapamycin/variants/MBY4_vs_W303_clair3

echo "--- variant count ---"
zcat /N/scratch/bochman/mby4_rapamycin/variants/MBY4_vs_W303_clair3/merge_output.vcf.gz | grep -vc '^#'
