#!/bin/bash
#SBATCH -A r02049
#SBATCH -p general
#SBATCH -J lachancea_tree
#SBATCH -t 2:00:00
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH -o /N/scratch/bochman/lachancea_pop/logs/tree_%j.out

source ~/miniconda3/etc/profile.d/conda.sh
conda activate popgen
Rscript /N/scratch/bochman/lachancea_pop/pipeline/13_build_tree.R
