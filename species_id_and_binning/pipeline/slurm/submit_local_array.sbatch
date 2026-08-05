#!/bin/bash
#SBATCH -J yeast_local
#SBATCH -A r02049
#SBATCH -p general
#SBATCH -t 12:00:00
#SBATCH -c 16
#SBATCH --mem=64G
#SBATCH --array=1-9%3
#SBATCH -o /N/scratch/%u/yeast_id/logs/local_%A_%a.out
#SBATCH -e /N/scratch/%u/yeast_id/logs/local_%A_%a.err
#
# One array task per sample: QC, filter, assemble, BUSCO, marker extraction.
# %3 caps concurrency at 3 to be considerate of the shared partition; raise
# if you have headroom. If sample YH229 (largest file, 6.7GB compressed -
# verify it isn't higher coverage / contaminated than the others) times out
# or OOMs, resubmit just that array index with bumped -t/--mem:
#   sbatch --array=9 --time=24:00:00 --mem=128G submit_local_array.sbatch
set -euo pipefail
ROOT="/N/scratch/${USER}/yeast_id"
cd "$ROOT"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.tsv | cut -f1)
echo "Array task ${SLURM_ARRAY_TASK_ID} -> sample $SAMPLE"

source "/N/u/${USER}/Quartz/miniconda3/etc/profile.d/conda.sh"
conda activate yeast-id

bash "${ROOT}/pipeline/scripts/02_per_sample_qc_assemble.sh" "$SAMPLE"
