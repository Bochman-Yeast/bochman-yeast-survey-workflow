#!/bin/bash
#SBATCH --job-name=MBY4_sniffles_s288c
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/sv/sniffles_s288c_%j.log

# STATUS: untested template.

source ~/.bashrc
conda activate mby4_rapamycin
cd /N/scratch/bochman/mby4_rapamycin/sv

sniffles --version   # confirm this reports Sniffles2, not Sniffles1

BAM=/N/scratch/bochman/mby4_rapamycin/mapping/MBY4_vs_S288c.sorted.bam
REF=/N/scratch/bochman/mby4_rapamycin/reference/S288c_R64.fna

sniffles \
  --input $BAM \
  --reference $REF \
  --vcf MBY4_vs_S288c.sniffles.vcf \
  --threads 8

echo "--- SV count ---"
grep -vc '^#' MBY4_vs_S288c.sniffles.vcf
