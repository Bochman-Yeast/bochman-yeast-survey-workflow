#!/bin/bash
#SBATCH -J yeast_ani
#SBATCH -A r02049
#SBATCH -p general
#SBATCH -t 04:00:00
#SBATCH -c 8
#SBATCH --mem=16G
#SBATCH --array=1-9%2
#SBATCH -o /N/scratch/%u/yeast_id/logs/ani_%A_%a.out
#SBATCH -e /N/scratch/%u/yeast_id/logs/ani_%A_%a.err
#
# %2 concurrency: reference genome downloads are network calls guarded by
# flock, so races are safe but there's no point hammering NCBI in parallel.
# Submit only after submit_blast.sbatch has completed.
set -euo pipefail
ROOT="/N/scratch/${USER}/yeast_id"
cd "$ROOT"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.tsv | cut -f1)
echo "Array task ${SLURM_ARRAY_TASK_ID} -> sample $SAMPLE"

source "/N/u/${USER}/Quartz/miniconda3/etc/profile.d/conda.sh"
conda activate yeast-id

bash "${ROOT}/pipeline/scripts/04_ani_analysis.sh" "$SAMPLE"
