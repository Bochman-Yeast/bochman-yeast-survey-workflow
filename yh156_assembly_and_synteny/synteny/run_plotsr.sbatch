#!/bin/bash
#SBATCH --job-name=YH156_plotsr
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=00:20:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=/N/scratch/bochman/yeast_id/results/YH156_v3_canu/vs_sversatilis/plotsr_%j.log

source ~/.bashrc
export OPENBLAS_NUM_THREADS=1
conda activate synteny
cd /N/scratch/bochman/yeast_id/results/YH156_v3_canu/vs_sversatilis

plotsr --sr YH156_sv_syri.out --genomes genomes.txt -o YH156_vs_sversatilis_synteny.png -W 10 -H 6
