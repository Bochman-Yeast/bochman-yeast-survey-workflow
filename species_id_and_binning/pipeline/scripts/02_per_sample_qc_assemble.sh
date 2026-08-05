#!/bin/bash
# Per-sample: QC -> filter -> assemble -> BUSCO -> rRNA markers (ITS, LSU D1/D2).
# Idempotent: each step is skipped if its output already exists.
# A failure here aborts THIS sample only (exit 1); it does not touch other
# samples, which run as independent Slurm array tasks.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/config.sh"
source "$DIR/scripts/lib.sh"

SAMPLE="${1:?Usage: 02_per_sample_qc_assemble.sh <sample>}"
FASTQ=$(awk -F'\t' -v s="$SAMPLE" '$1==s{print $2}' "$SAMPLE_SHEET")
[[ -n "$FASTQ" ]] || { echo "Sample $SAMPLE not found in $SAMPLE_SHEET"; exit 1; }

SDIR="${RESULTS_DIR}/${SAMPLE}"
mkdir -p "$SDIR"/{qc/nanoplot,filtered,assembly,busco,markers,logs}
exec > >(tee -a "${SDIR}/logs/02_local.log") 2>&1

echo_versions
log "Sample: $SAMPLE  Input: $FASTQ"

# 1. seqkit stats (raw)
if ! skip_if_done "${SDIR}/qc/seqkit_stats_raw.tsv" "seqkit stats (raw)"; then
  run_or_fail "seqkit stats raw" seqkit stats -a -T "$FASTQ" > "${SDIR}/qc/seqkit_stats_raw.tsv"
fi

# 2. NanoPlot (raw)
if ! skip_if_done "${SDIR}/qc/nanoplot/NanoStats.txt" "NanoPlot"; then
  run_or_fail "NanoPlot" NanoPlot --fastq "$FASTQ" -o "${SDIR}/qc/nanoplot" -t "$THREADS" --plots dot
fi

# 3. chopper filter
FILT="${SDIR}/filtered/${SAMPLE}.filt.fastq.gz"
if ! skip_if_done "$FILT" "chopper filter"; then
  run_or_fail "chopper" bash -c "zcat -f '$FASTQ' | chopper -q $MIN_Q -l $MIN_LEN -t $THREADS | gzip > '$FILT'" || rm -f "$FILT"
fi
[[ -s "$FILT" ]] || { log "FATAL: no filtered reads for $SAMPLE, aborting sample"; exit 1; }

# 3b. seqkit stats (filtered) - this is the reads_pass count for the summary
if ! skip_if_done "${SDIR}/qc/seqkit_stats_filtered.tsv" "seqkit stats (filtered)"; then
  run_or_fail "seqkit stats filtered" seqkit stats -a -T "$FILT" > "${SDIR}/qc/seqkit_stats_filtered.tsv"
fi

# 4. flye assembly
ASM="${SDIR}/assembly/assembly.fasta"
if ! skip_if_done "$ASM" "flye assembly"; then
  run_or_fail "flye" flye --nano-hq "$FILT" --out-dir "${SDIR}/assembly" --threads "$THREADS" --genome-size "$GENOME_SIZE_HINT"
fi
if [[ ! -s "$ASM" ]]; then
  log "FATAL: flye produced no assembly for $SAMPLE, aborting sample"
  exit 1
fi
cp -f "${SDIR}/assembly/assembly_info.txt" "${SDIR}/qc/assembly_info.txt" 2>/dev/null || true

# 5. BUSCO (glob check: exact short_summary filename varies by BUSCO version)
BUSCO_DIR="${SDIR}/busco"
if compgen -G "${BUSCO_DIR}/short_summary*.txt" > /dev/null; then
  log "SKIP (already done): BUSCO"
else
  if ! run_or_fail "busco primary ($BUSCO_LINEAGE_PRIMARY)" busco -i "$ASM" -o busco -l "$BUSCO_LINEAGE_PRIMARY" \
        --out_path "${SDIR}" -m genome -c "$THREADS" --download_path "$BUSCO_DL_DIR" -f; then
    log "Primary BUSCO lineage failed, falling back to $BUSCO_LINEAGE_FALLBACK"
    echo "fallback_lineage_used=$BUSCO_LINEAGE_FALLBACK" >> "${SDIR}/qc/busco_notes.txt"
    run_or_fail "busco fallback ($BUSCO_LINEAGE_FALLBACK)" busco -i "$ASM" -o busco -l "$BUSCO_LINEAGE_FALLBACK" \
        --out_path "${SDIR}" -m genome -c "$THREADS" --download_path "$BUSCO_DL_DIR" -f
  fi
fi

# 6. barrnap
GFF="${SDIR}/markers/barrnap.gff3"
if ! skip_if_done "$GFF" "barrnap"; then
  run_or_fail "barrnap" bash -c "barrnap --kingdom fun --threads $THREADS '$ASM' > '$GFF'"
fi

# 7. LSU D1/D2 domain: first ~700bp of the longest 28S_rRNA hit, strand-aware
LSU_FA="${SDIR}/markers/LSU_D1D2.fasta"
if ! skip_if_done "$LSU_FA" "LSU D1/D2 extraction"; then
  run_or_fail "extract LSU D1/D2" python3 "$DIR/scripts/extract_lsu.py" "$GFF" "$ASM" "$LSU_FA" "$SAMPLE" 700
fi

# 8. ITSx (primary ITS extraction method). ITSx's HMMER pipeline caps
# single-sequence input at 100kb, so it cannot run on whole contigs - first
# slice out a padded window around the rRNA locus using barrnap's coordinates.
RRNA_REGION="${SDIR}/markers/rrna_region.fasta"
if ! skip_if_done "$RRNA_REGION" "extract rRNA region for ITSx"; then
  run_or_fail "extract rRNA region" python3 "$DIR/scripts/extract_rrna_region.py" "$GFF" "$ASM" "$RRNA_REGION" "$SAMPLE" 1000
fi

ITS_SUMMARY="${SDIR}/markers/itsx/${SAMPLE}.summary.txt"
if [[ -s "$RRNA_REGION" ]]; then
  if ! skip_if_done "$ITS_SUMMARY" "ITSx"; then
    mkdir -p "${SDIR}/markers/itsx"
    run_or_fail "ITSx" ITSx -i "$RRNA_REGION" -o "${SDIR}/markers/itsx/${SAMPLE}" --cpu "$THREADS" -t Fungi --preserve T
  fi
else
  log "No rRNA region extracted (barrnap found no paired 18S/28S), skipping ITSx"
fi

ITS_FA="${SDIR}/markers/ITS.fasta"
if [[ -s "${SDIR}/markers/itsx/${SAMPLE}.full.fasta" ]]; then
  cp -f "${SDIR}/markers/itsx/${SAMPLE}.full.fasta" "$ITS_FA"
elif compgen -G "${SDIR}/markers/itsx/${SAMPLE}.ITS*.fasta" > /dev/null; then
  cat "${SDIR}/markers/itsx/${SAMPLE}".ITS*.fasta > "$ITS_FA"
fi
if [[ ! -s "$ITS_FA" ]]; then
  log "ITSx found no confident ITS; falling back to barrnap 18S-end -> 28S-start interval"
  if run_or_fail "extract ITS fallback" python3 "$DIR/scripts/extract_its_fallback.py" "$GFF" "$ASM" "$ITS_FA" "$SAMPLE"; then
    echo "fallback_method=barrnap_interval" >> "${SDIR}/markers/its_notes.txt"
  fi
fi

touch "${SDIR}/.step02.done"
log "Sample $SAMPLE local pipeline complete."
