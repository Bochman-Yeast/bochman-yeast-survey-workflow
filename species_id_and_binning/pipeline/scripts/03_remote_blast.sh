#!/bin/bash
# Remote BLAST of ITS and LSU D1/D2 markers against nt for ALL samples.
# Deliberately sequential (not an array job) with a politeness delay between
# calls - NCBI's remote BLAST service asks that you not hammer it with
# concurrent requests. 9 samples x 2 markers x ~15s delay is trivial either way.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/config.sh"
source "$DIR/scripts/lib.sh"

exec > >(tee -a "${LOG_DIR}/03_remote_blast.log") 2>&1
echo_versions

OUTFMT="6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qcovs stitle"

while IFS=$'\t' read -r SAMPLE FASTQ; do
  SDIR="${RESULTS_DIR}/${SAMPLE}"
  mkdir -p "${SDIR}/blast"
  for MARKER in ITS LSU_D1D2; do
    QFA="${SDIR}/markers/${MARKER}.fasta"
    OUT="${SDIR}/blast/${MARKER}.blast.tsv"
    [[ -s "$QFA" ]] || { log "[$SAMPLE] no $MARKER fasta, skipping"; continue; }
    if [[ -s "$OUT" ]]; then
      log "[$SAMPLE] SKIP $MARKER blast (already done)"
      continue
    fi
    log "[$SAMPLE] remote BLAST $MARKER ..."
    if blastn -remote -db nt -query "$QFA" -outfmt "$OUTFMT" -max_target_seqs 5 \
         -out "${OUT}.tmp" 2> "${SDIR}/blast/${MARKER}.blast.err"; then
      mv "${OUT}.tmp" "$OUT"
      log "[$SAMPLE] $MARKER blast OK ($(wc -l < "$OUT") hits)"
    else
      log "[$SAMPLE] $MARKER blast FAILED, see ${SDIR}/blast/${MARKER}.blast.err"
      echo -e "$(date '+%F %T')\t${SAMPLE}\tblast_${MARKER}\tfailed" >> "${RESULTS_DIR}/FAILURES.tsv"
    fi
    sleep 15
  done
done < "$SAMPLE_SHEET"

log "Remote BLAST pass complete."
