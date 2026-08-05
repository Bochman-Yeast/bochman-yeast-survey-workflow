#!/bin/bash
# Scans a directory of FASTQ files, derives sample names, writes samples.tsv,
# and prints the mapping for review. Run this and eyeball the output BEFORE
# submitting any heavy jobs.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/config.sh"

SRC_DIR="${1:?Usage: 00_make_sample_sheet.sh <path-to-fastq-dir>}"

> "$SAMPLE_SHEET"
echo "Detected sample -> file mapping:"
printf "%-12s %-40s %10s\n" "SAMPLE" "FILE" "SIZE"
shopt -s nullglob
for f in "$SRC_DIR"/*.fastq.gz "$SRC_DIR"/*.fq.gz "$SRC_DIR"/*.fastq "$SRC_DIR"/*.fq; do
  base=$(basename "$f")
  # expected pattern: LHGHSF_<n>_<sample>.fastq.gz -> sample = last underscore field
  sample=$(echo "$base" | sed -E 's/\.(fastq|fq)(\.gz)?$//' | sed -E 's/^.*_([^_]+)$/\1/')
  size=$(du -h "$f" | cut -f1)
  printf "%-12s %-40s %10s\n" "$sample" "$base" "$size"
  printf "%s\t%s\n" "$sample" "$f" >> "$SAMPLE_SHEET"
done
shopt -u nullglob

n=$(wc -l < "$SAMPLE_SHEET")
echo ""
echo "$n samples written to $SAMPLE_SHEET"
echo "Review this file. If it looks wrong, edit $SAMPLE_SHEET directly before proceeding."
