#!/bin/bash
#SBATCH --job-name=MBY4_medaka
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/assembly/medaka_%j.log

# STATUS: untested template. Basecaller confirmed from read headers (2026-08-09):
# dna_r10.4.1_e8.2_400bps_sup@v4.3.0 (see ../NOTES.md). The model name below
# (r1041_e82_400bps_sup_v430) is what web search indicates is the matching medaka model for
# that exact basecaller version, but has NOT been confirmed against this Quartz install's
# actual model list -- run `medaka tools list_models | grep -i r1041_e82_400bps_sup` first
# and correct this if the exact string differs (e.g. a dotted version, or if v430 isn't
# available and the nearest older/newer version must be substituted -- log that substitution
# in ../NOTES.md if so, since it's a real (if usually minor) accuracy-profile mismatch).

source ~/.bashrc
conda activate mby4_rapamycin
cd /N/scratch/bochman/mby4_rapamycin/assembly

medaka --version
medaka tools list_models | grep -i r1041_e82_400bps_sup || echo "WARNING: no matching model found -- verify before proceeding"

medaka_consensus \
  -i /N/scratch/bochman/mby4_rapamycin/raw/MBY4.fastq.gz \
  -d flye_MBY4/assembly.fasta \
  -o medaka_polish \
  -m r1041_e82_400bps_sup_v430 \
  -t 16

echo "--- polished assembly stats ---"
seqkit stats -a medaka_polish/consensus.fasta
