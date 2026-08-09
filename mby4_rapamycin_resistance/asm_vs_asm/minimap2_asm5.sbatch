#!/bin/bash
#SBATCH --job-name=MBY4_asm5
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/asm_vs_asm/asm5_%j.log

# STATUS: untested template. W303 alignment blocked until accession resolved
# (../reference/PROVENANCE.md) — S288c alignment can run once the polished MBY4 assembly
# exists.

source ~/.bashrc
conda activate mby4_rapamycin
cd /N/scratch/bochman/mby4_rapamycin/asm_vs_asm

minimap2 --version

QRY=/N/scratch/bochman/mby4_rapamycin/assembly/medaka_polish/consensus.fasta
REF_S288C=/N/scratch/bochman/mby4_rapamycin/reference/S288c_R64.fna
REF_W303=/N/scratch/bochman/mby4_rapamycin/reference/W303.fna   # PLACEHOLDER — path depends on accession resolution

minimap2 -x asm5 -t 8 $REF_S288C $QRY > MBY4_vs_S288c.asm5.paf
minimap2 -x asm5 -t 8 $REF_W303 $QRY > MBY4_vs_W303.asm5.paf

echo "--- PAF alignment counts ---"
wc -l MBY4_vs_S288c.asm5.paf MBY4_vs_W303.asm5.paf
