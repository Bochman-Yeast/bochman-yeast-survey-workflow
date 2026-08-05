#!/bin/bash
#SBATCH -A r02049
#SBATCH -p general
#SBATCH -J lachancea_pca
#SBATCH -t 30:00
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH -o /N/scratch/bochman/lachancea_pop/logs/pca_%j.out

source ~/miniconda3/etc/profile.d/conda.sh
conda activate popgen
Rscript /N/scratch/bochman/lachancea_pop/pipeline/12_pca_crosscheck.R
