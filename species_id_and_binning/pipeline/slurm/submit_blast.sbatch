#!/bin/bash
#SBATCH -J yeast_blast
#SBATCH -A r02049
#SBATCH -p general
#SBATCH -t 06:00:00
#SBATCH -c 2
#SBATCH --mem=8G
#SBATCH -o /N/scratch/%u/yeast_id/logs/blast_%j.out
#SBATCH -e /N/scratch/%u/yeast_id/logs/blast_%j.err
#
# Single job, NOT an array - remote BLAST calls run sequentially inside
# 03_remote_blast.sh out of courtesy to NCBI. Submit this only after ALL
# local-array tasks have finished (it needs every sample's marker fastas).
set -euo pipefail
ROOT="/N/scratch/${USER}/yeast_id"
cd "$ROOT"

source "/N/u/${USER}/Quartz/miniconda3/etc/profile.d/conda.sh"
conda activate yeast-id

bash "${ROOT}/pipeline/scripts/03_remote_blast.sh"
