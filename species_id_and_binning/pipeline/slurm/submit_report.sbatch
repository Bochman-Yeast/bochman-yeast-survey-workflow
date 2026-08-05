#!/bin/bash
#SBATCH -J yeast_report
#SBATCH -A r02049
#SBATCH -p debug
#SBATCH -t 00:10:00
#SBATCH -c 1
#SBATCH --mem=4G
#SBATCH -o /N/scratch/%u/yeast_id/logs/report_%j.out
#SBATCH -e /N/scratch/%u/yeast_id/logs/report_%j.err
#
# Light aggregation step - could also just be run directly on the login node.
set -euo pipefail
ROOT="/N/scratch/${USER}/yeast_id"
cd "$ROOT"

source "/N/u/${USER}/Quartz/miniconda3/etc/profile.d/conda.sh"
conda activate yeast-id
source "${ROOT}/pipeline/config.sh"

python3 "${ROOT}/pipeline/scripts/05_consensus_report.py"
