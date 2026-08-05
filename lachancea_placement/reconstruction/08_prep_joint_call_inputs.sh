#!/bin/bash
# Build the two small input files the joint-calling scripts depend on:
#   ref/contigs.txt        - one reference contig name per line (drives the shard array)
#   pubpanel_bamlist.txt   - one dedup BAM path per line, all 145 (bcftools mpileup -b input)
# Run this only after 01_prep_reference.sh and the full alignment array have completed.
set -euo pipefail

WORKDIR=/N/scratch/bochman/lachancea_pop
cd "$WORKDIR"

cut -f1 ref/CBS6340.fna.fai > ref/contigs.txt
echo "Wrote $(wc -l < ref/contigs.txt) contigs to ref/contigs.txt:"
cat ref/contigs.txt

find aligned/pubpanel -name "*.dedup.bam" | sort > pubpanel_bamlist.txt
n=$(wc -l < pubpanel_bamlist.txt)
echo ""
echo "Wrote $n BAM paths to pubpanel_bamlist.txt (expect 145)."
if [ "$n" -ne 145 ]; then
  echo "WARNING: not 145 - check which strains are missing before submitting the joint-call array:"
  comm -23 <(tail -n +2 download_manifest.tsv | cut -f7 | sort) \
           <(basename -a $(find aligned/pubpanel -name "*.dedup.bam") | sed 's/\.dedup\.bam$//' | sort)
fi
