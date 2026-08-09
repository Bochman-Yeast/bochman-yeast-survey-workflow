#!/bin/bash
#SBATCH --job-name=MBY4_map_s288c
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/mapping/map_s288c_%j.log

# STATUS: untested template. MAP_PRESET below must match the basecaller-model decision
# logged in ../NOTES.md (see ../raw/README.md) — map-ont for standard reads, lr:hq for
# high-accuracy Q20+/R10.4.1-sup reads. Keep consistent with map_to_w303.sbatch.

source ~/.bashrc
conda activate mby4_rapamycin
cd /N/scratch/bochman/mby4_rapamycin/mapping

minimap2 --version
samtools --version | head -1

MAP_PRESET=map-ont   # PLACEHOLDER — confirm before running
REF=/N/scratch/bochman/mby4_rapamycin/reference/S288c_R64.fna
READS=/N/scratch/bochman/mby4_rapamycin/raw/MBY4.fastq.gz

minimap2 -ax $MAP_PRESET -t 16 $REF $READS \
  | samtools sort -@ 16 -o MBY4_vs_S288c.sorted.bam -
samtools index MBY4_vs_S288c.sorted.bam
samtools flagstat MBY4_vs_S288c.sorted.bam
samtools coverage MBY4_vs_S288c.sorted.bam
