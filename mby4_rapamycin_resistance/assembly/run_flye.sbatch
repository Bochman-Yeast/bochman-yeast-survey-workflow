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

# STATUS: untested template. DO NOT RUN until:
#   1. ../raw/ QC (step 1) has been reported and confirmed with the user (explicit
#      check-in point from the original task)
#   2. The --nano-raw vs --nano-hq choice below has been made based on MBY4's actual
#      basecaller/model (see ../raw/README.md) and logged in ../NOTES.md

source ~/.bashrc
conda activate mby4_rapamycin

flye --version

READ_MODE=--nano-hq   # PLACEHOLDER — confirm against actual basecaller before running;
                       # use --nano-raw instead if reads are not modern sup/hac R10.4.1-class

flye $READ_MODE /N/scratch/bochman/mby4_rapamycin/raw/MBY4.fastq.gz \
  --out-dir /N/scratch/bochman/mby4_rapamycin/assembly/flye_MBY4 \
  --threads 16 \
  --genome-size 12.1m

echo "--- assembly-info.txt ---"
cat /N/scratch/bochman/mby4_rapamycin/assembly/flye_MBY4/assembly_info.txt
