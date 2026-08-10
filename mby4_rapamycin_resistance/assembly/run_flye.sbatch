#!/bin/bash
#SBATCH --job-name=MBY4_flye
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/assembly/flye_%j.log

# STATUS: untested template. DO NOT RUN until ../raw/ QC (step 1) has been reported and
# confirmed with the user (explicit check-in point from the original task).
#
# Basecaller confirmed from read headers (2026-08-09): dna_r10.4.1_e8.2_400bps_sup@v4.3.0
# (R10.4.1 chemistry, Dorado "sup" super-accuracy model) -- see ../NOTES.md. --nano-hq is
# the correct mode for this accuracy class.

source ~/.bashrc
conda activate mby4_rapamycin

flye --version

READ_MODE=--nano-hq   # confirmed for dna_r10.4.1_e8.2_400bps_sup@v4.3.0 -- see ../NOTES.md

flye $READ_MODE /N/scratch/bochman/mby4_rapamycin/raw/MBY4.fastq.gz \
  --out-dir /N/scratch/bochman/mby4_rapamycin/assembly/flye_MBY4 \
  --threads 16 \
  --genome-size 12.1m

echo "--- assembly-info.txt ---"
cat /N/scratch/bochman/mby4_rapamycin/assembly/flye_MBY4/assembly_info.txt
