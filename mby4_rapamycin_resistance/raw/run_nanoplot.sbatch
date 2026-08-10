#!/bin/bash
#SBATCH --job-name=MBY4_nanoplot
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/raw/nanoplot_%j.log

# STATUS: untested template. Conda env name / NanoPlot version not yet confirmed on Quartz —
# see ../environment.yml. Update env name below to match whatever is actually built.

source ~/.bashrc
conda activate mby4_rapamycin
cd /N/scratch/bochman/mby4_rapamycin/raw

NanoPlot --version

NanoPlot \
  --fastq MBY4.fastq.gz \
  --outdir nanoplot_MBY4 \
  --threads 4 \
  --N50 \
  --tsv_stats

echo "--- estimated coverage (12,157,105 bp S288c genome size) ---"
python3 - <<'PYEOF'
import csv
with open("nanoplot_MBY4/NanoStats.txt") as f:
    for line in f:
        print(line.rstrip())
PYEOF
