#!/bin/bash
set -e
CONTIGS=YH156_canu.contigs.fasta
REF=/N/scratch/bochman/yeast_id/sjaponicus_ref/ncbi_dataset/data/GCF_000149845.2/GCF_000149845.2_SJ5_genomic.fna

seqkit grep -p tig00000054 $CONTIGS | seqkit subseq -r 1:98650      | seqkit replace -p "^tig00000054.*" -r "tig00000054_chr1arm" > split_A.fasta
seqkit grep -p tig00000054 $CONTIGS | seqkit subseq -r 98651:186990 | seqkit replace -p "^tig00000054.*" -r "tig00000054_chr2arm" > split_B.fasta
seqkit grep -p tig00000048 $CONTIGS | seqkit subseq -r 1:107070     | seqkit replace -p "^tig00000048.*" -r "tig00000048_chr2arm" > split_C.fasta
seqkit grep -p tig00000048 $CONTIGS | seqkit subseq -r 107071:270773 | seqkit replace -p "^tig00000048.*" -r "tig00000048_chr1arm" > split_D.fasta

cat split_A.fasta split_B.fasta split_C.fasta split_D.fasta > split_pieces.fasta

seqkit grep -v -p tig00000048 -p tig00000054 $CONTIGS > YH156_canu.contigs.dechimerized.fasta
cat split_pieces.fasta >> YH156_canu.contigs.dechimerized.fasta

echo "=== Original vs de-chimerized stats ==="
seqkit stats -a $CONTIGS
seqkit stats -a YH156_canu.contigs.dechimerized.fasta

echo ""
echo "=== Verifying each split piece now maps cleanly to one chromosome ==="
minimap2 -x asm10 -t 8 $REF split_pieces.fasta 2>/dev/null | awk 'BEGIN{OFS="\t"}{print $1,"len="$2,"->",$6,"tstart="$8,"tend="$9,"matches="$10,"alnlen="$11}' | sort -k1,1
