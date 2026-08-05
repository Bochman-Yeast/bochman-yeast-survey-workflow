#!/bin/bash
#SBATCH --job-name=YH156_syri_sv2
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=/N/scratch/bochman/yeast_id/results/YH156_v3_canu/vs_sversatilis/syri_sv2_%j.log

source ~/.bashrc
cd /N/scratch/bochman/yeast_id/results/YH156_v3_canu/vs_sversatilis
conda activate synteny

REF=/N/scratch/bochman/yeast_id/refs/Schizosaccharomyces_versatilis/genome.fna

syri -c YH156_vs_sv.filtered.coords -d YH156_vs_sv.filtered.delta -r $REF -q YH156_pseudochroms_sv.fasta --dir . --prefix YH156_sv_ --nc 4
