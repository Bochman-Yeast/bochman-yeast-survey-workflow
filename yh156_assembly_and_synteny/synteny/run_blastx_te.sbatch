#!/bin/bash
#SBATCH --job-name=YH156_blastx_te
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=/N/scratch/bochman/yeast_id/results/YH156_v3_canu/blastx_te_%j.log

source ~/.bashrc
conda activate yeast-id
cd /N/scratch/bochman/yeast_id/results/YH156_v3_canu

blastx -remote -db nr -query repeat_163_small.fasta -entrez_query "fungi[Organism]" \
  -outfmt "6 qseqid sseqid pident length evalue bitscore stitle" -max_target_seqs 10 -max_hsps 1 -evalue 1e-5 \
  > repeat_163_blastx_fungi.tsv

blastx -remote -db nr -query repeat_177_small.fasta -entrez_query "fungi[Organism]" \
  -outfmt "6 qseqid sseqid pident length evalue bitscore stitle" -max_target_seqs 10 -max_hsps 1 -evalue 1e-5 \
  > repeat_177_blastx_fungi.tsv

echo "=== tig00000163 ==="
cat repeat_163_blastx_fungi.tsv
echo "=== tig00000177 ==="
cat repeat_177_blastx_fungi.tsv
