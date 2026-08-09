#!/bin/bash
#SBATCH --job-name=MBY4_map_w303
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/mapping/map_w303_%j.log

# STATUS: untested template. W303 accession resolved (../reference/PROVENANCE.md —
# GCA_965282845.1, downloaded and staged). Basecaller confirmed from read headers
# (2026-08-09): dna_r10.4.1_e8.2_400bps_sup@v4.3.0 (see ../NOTES.md) -- lr:hq preset.

source ~/.bashrc
conda activate mby4_rapamycin
cd /N/scratch/bochman/mby4_rapamycin/mapping

minimap2 --version
samtools --version | head -1

MAP_PRESET=lr:hq   # confirmed for dna_r10.4.1_e8.2_400bps_sup@v4.3.0 -- see ../NOTES.md, must match map_to_s288c.sbatch
REF=/N/scratch/bochman/mby4_rapamycin/reference/W303.fna   # PLACEHOLDER — path depends on accession resolution
READS=/N/scratch/bochman/mby4_rapamycin/raw/MBY4.fastq.gz

minimap2 -ax $MAP_PRESET -t 16 $REF $READS \
  | samtools sort -@ 16 -o MBY4_vs_W303.sorted.bam -
samtools index MBY4_vs_W303.sorted.bam
samtools flagstat MBY4_vs_W303.sorted.bam
samtools coverage MBY4_vs_W303.sorted.bam
