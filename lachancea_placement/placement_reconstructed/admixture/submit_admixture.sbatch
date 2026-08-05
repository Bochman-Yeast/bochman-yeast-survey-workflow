#!/bin/bash
#SBATCH -A r02049
#SBATCH -p general
#SBATCH -J lachancea_admixture
#SBATCH -t 1:00:00
#SBATCH -c 8
#SBATCH --mem=16G
#SBATCH -o /N/scratch/bochman/lachancea_pop/logs/admixture_%j.out

bash /N/scratch/bochman/lachancea_pop/pipeline/11_run_admixture_supervised.sh
