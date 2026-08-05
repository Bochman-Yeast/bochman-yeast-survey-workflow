#!/bin/bash
#SBATCH --job-name=YH156_medaka_canu
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --output=/N/scratch/bochman/yeast_id/results/YH156_v3_canu/medaka_%j.log

source ~/.bashrc
conda activate yeast-id
cd /N/scratch/bochman/yeast_id

medaka_consensus \
  -i results/YH156_v2/filtered/YH156_combined.filt.fastq.gz \
  -d results/YH156_v3_canu/YH156_canu.contigs.dechimerized.fasta \
  -o results/YH156_v3_canu/medaka_polish \
  -m r1041_e82_400bps_sup_v5.2.0 \
  -t 16
