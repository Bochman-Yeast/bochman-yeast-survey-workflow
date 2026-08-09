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

# STATUS: untested template. Model name below is a placeholder copied from
# ../../yh156_assembly_and_synteny/assembly/medaka_polish.sbatch for illustration only —
# replace with the model matching MBY4's actual flow cell / basecaller
# (`medaka tools list_models`) before running.

source ~/.bashrc
conda activate mby4_rapamycin
cd /N/scratch/bochman/mby4_rapamycin/assembly

medaka --version

medaka_consensus \
  -i /N/scratch/bochman/mby4_rapamycin/raw/MBY4.fastq.gz \
  -d flye_MBY4/assembly.fasta \
  -o medaka_polish \
  -m r1041_e82_400bps_sup_v5.2.0 \
  -t 16

echo "--- polished assembly stats ---"
seqkit stats -a medaka_polish/consensus.fasta
