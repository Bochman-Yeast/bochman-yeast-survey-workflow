#!/bin/bash
# tor_pathway_lookup.sh — pull MBY4-specific variant status at each TOR-pathway gene.
#
# STATUS: untested template. Coordinates in tor_pathway_genes.tsv are now fully confirmed
# (GFF3 + UniProt, see that file's header). DO NOT RUN until the MBY4-specific call sets
# from intersect_mby4_specific.sh exist.

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

echo "NOTE: chr${chrom} naming above assumes 'chrI'..'chrXVI' style headers -- confirmed"
echo "against both reference/S288c_R64.fna and reference/W303.fna (both renamed to this"
echo "convention, see reference/PROVENANCE.md). This script targets the S288c BAM"
echo "(COVERAGE var above) specifically -- rerun against the W303 BAM/VCFs separately if a"
echo "W303-side pileup check is also wanted for a given candidate."
