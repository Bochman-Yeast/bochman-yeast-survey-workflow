#!/bin/bash
#SBATCH --job-name=MBY4_dnadiff
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=/N/scratch/bochman/mby4_rapamycin/asm_vs_asm/dnadiff_%j.log

# STATUS: untested template. Second, independent method alongside minimap2_asm5.sbatch —
# per the original task's instruction to use asm5 or MUMmer/dnadiff (interpreted here as
# both, for cross-validation, following ../../yh156_assembly_and_synteny/synteny/'s use of
# nucmer/delta-filter as its primary alignment method).

source ~/.bashrc
conda activate mby4_rapamycin
cd /N/scratch/bochman/mby4_rapamycin/asm_vs_asm

dnadiff --version 2>&1 | head -3 || true

QRY=/N/scratch/bochman/mby4_rapamycin/assembly/medaka_polish/consensus.fasta
REF_S288C=/N/scratch/bochman/mby4_rapamycin/reference/S288c_R64.fna
REF_W303=/N/scratch/bochman/mby4_rapamycin/reference/W303.fna   # PLACEHOLDER — path depends on accession resolution

dnadiff -p MBY4_vs_S288c $REF_S288C $QRY
dnadiff -p MBY4_vs_W303 $REF_W303 $QRY

echo "--- dnadiff summary reports ---"
cat MBY4_vs_S288c.report
cat MBY4_vs_W303.report
