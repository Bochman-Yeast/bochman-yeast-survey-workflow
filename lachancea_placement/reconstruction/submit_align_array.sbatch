#!/bin/bash
#SBATCH -A r02049
#SBATCH -p general
#SBATCH -J lachancea_align
#SBATCH -t 45:00
#SBATCH -c 8
#SBATCH --mem=16G
#SBATCH --array=1-145%20
#SBATCH -o /N/scratch/bochman/lachancea_pop/logs/align/slurm_%A_%a.out

source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id
set -euo pipefail

WORKDIR=/N/scratch/bochman/lachancea_pop
TASKLIST="$WORKDIR/align_tasklist.txt"

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$TASKLIST")
RUN=$(echo "$LINE" | cut -f1)
R1=$(echo "$LINE" | cut -f2)
R2=$(echo "$LINE" | cut -f3)

bash "$WORKDIR/pipeline/02_align_pubstrain.sh" "$RUN" "$WORKDIR/$R1" "$WORKDIR/$R2"
