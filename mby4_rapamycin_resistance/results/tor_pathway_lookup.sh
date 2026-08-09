#!/bin/bash
# tor_pathway_lookup.sh — pull MBY4-specific variant status at each TOR-pathway gene.
#
# STATUS: untested template. DO NOT RUN until tor_pathway_genes.tsv coordinates are
# verified (see that file's header) and the MBY4-specific call sets from
# intersect_mby4_specific.sh exist.

set -euo pipefail

GENES_TSV=/N/scratch/bochman/mby4_rapamycin/results/tor_pathway_genes.tsv
SNV_VCF=/N/scratch/bochman/mby4_rapamycin/results/snv_isec/0000.vcf   # MBY4-specific SNVs/indels
SV_VCF=/N/scratch/bochman/mby4_rapamycin/results/sv_isec/0000.vcf     # MBY4-specific SVs
COVERAGE=/N/scratch/bochman/mby4_rapamycin/mapping/MBY4_vs_S288c.sorted.bam

while IFS=$'\t' read -r name systematic chrom start end strand notes; do
  [[ "$name" == \#* || "$name" == "standard_name" ]] && continue
  if [[ "$start" == "UNVERIFIED" ]]; then
    echo "=== $name ($systematic): coordinates unverified, skipping — fix tor_pathway_genes.tsv first ==="
    continue
  fi
  echo "=== $name ($systematic) chr$chrom:$start-$end ==="
  echo "-- MBY4-specific SNVs/indels in region --"
  bcftools view -r "chr${chrom}:${start}-${end}" "$SNV_VCF" 2>/dev/null | grep -v '^#' || echo "  none"
  echo "-- MBY4-specific SVs overlapping region --"
  bcftools view -r "chr${chrom}:${start}-${end}" "$SV_VCF" 2>/dev/null | grep -v '^#' || echo "  none"
  echo "-- depth at locus (flag if any position <20-30x) --"
  samtools depth -r "chr${chrom}:${start}-${end}" "$COVERAGE" \
    | awk '{sum+=$3; n++; if($3<20) low++} END {printf "  mean depth: %.1f over %d positions", sum/n, n; if(low>0) printf " — %d positions BELOW 20x, flag as low-confidence", low; print ""}'
  echo
done < "$GENES_TSV"

echo "NOTE: chr${chrom} naming above assumes the reference FASTA uses 'chrI'..'chrXVI' style"
echo "headers with region argument prefixed 'chr' + roman numeral from the TSV. Confirm"
echo "actual header naming in the downloaded S288c FASTA (grep '>' reference/S288c_R64.fna)"
echo "and adjust the chrom column / region string format in this script if it differs."
