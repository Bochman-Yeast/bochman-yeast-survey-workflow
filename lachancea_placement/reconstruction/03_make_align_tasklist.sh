#!/bin/bash
# Build a flat task list (one line per strain: run_accession r1_path r2_path)
# for the alignment array job, verifying both mates actually exist on disk first.
set -euo pipefail

WORKDIR=/N/scratch/bochman/lachancea_pop
cd "$WORKDIR"

TASKLIST="align_tasklist.txt"
> "$TASKLIST"

tail -n +2 download_manifest.tsv | cut -f7 | while read -r run; do
  r1="raw/${run}/${run}_1.fastq.gz"
  r2="raw/${run}/${run}_2.fastq.gz"
  if [ -s "$r1" ] && [ -s "$r2" ]; then
    echo -e "${run}\t${r1}\t${r2}" >> "$TASKLIST"
  else
    echo "MISSING: $run (r1=$([ -s "$r1" ] && echo ok || echo MISSING), r2=$([ -s "$r2" ] && echo ok || echo MISSING))"
  fi
done

n=$(wc -l < "$TASKLIST")
echo ""
echo "Task list has $n entries (expect 145)."
echo "If not 145, check the MISSING lines above before submitting the array job -"
echo "the download may still be running, or a run may have failed."
