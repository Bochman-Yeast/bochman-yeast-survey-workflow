#!/bin/bash
#SBATCH -A r02049
#SBATCH -p general
#SBATCH -J lachancea_jointcall
#SBATCH -t 2:00:00
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH -o /N/scratch/bochman/lachancea_pop/logs/jointcall_%A_%a.out

source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id
set -euo pipefail

WORKDIR=/N/scratch/bochman/lachancea_pop
CONTIGLIST="$WORKDIR/ref/contigs.txt"

CONTIG=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$CONTIGLIST")
bash "$WORKDIR/pipeline/04_joint_call_shard.sh" "$CONTIG"
