#!/bin/bash
# Diagnose a suspected mixed-culture/contamination signal for one sample
# against two candidate reference genomes: bins assembly contigs by best
# reference match, checks the read-level species fraction, and runs BUSCO
# on each contig bin. True co-culture should show substantial, comparable
# read-level support for both organisms and each bin assembling into a
# near-complete single-species genome on its own; barcode cross-talk
# typically shows up as a small minority read fraction instead.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/config.sh"
source "$DIR/scripts/lib.sh"

SAMPLE="${1:?Usage: investigate_mixed_sample.sh <sample> <ref1_fasta> <ref2_fasta>}"
REF1="${2:?ref1 fasta required}"
REF2="${3:?ref2 fasta required}"
REF1_NAME=$(basename "$(dirname "$REF1")")
REF2_NAME=$(basename "$(dirname "$REF2")")

SDIR="${RESULTS_DIR}/${SAMPLE}"
OUT="${SDIR}/mixed_investigation"
mkdir -p "$OUT" "${SDIR}/logs"
exec > >(tee -a "${SDIR}/logs/investigate_mixed.log") 2>&1
echo_versions

ASM="${SDIR}/assembly/assembly.fasta"
FILT="${SDIR}/filtered/${SAMPLE}.filt.fastq.gz"

log "=== Step 1: contig-level binning against $REF1_NAME and $REF2_NAME ==="
run_or_fail "minimap2 contigs vs $REF1_NAME" bash -c \
  "minimap2 -x asm10 -t $THREADS '$REF1' '$ASM' > '${OUT}/contigs_vs_${REF1_NAME}.paf' 2> '${OUT}/contigs_vs_${REF1_NAME}.log'"
run_or_fail "minimap2 contigs vs $REF2_NAME" bash -c \
  "minimap2 -x asm10 -t $THREADS '$REF2' '$ASM' > '${OUT}/contigs_vs_${REF2_NAME}.paf' 2> '${OUT}/contigs_vs_${REF2_NAME}.log'"

run_or_fail "bin contigs" python3 "$DIR/scripts/bin_contigs_by_reference.py" \
  "${OUT}/contigs_vs_${REF1_NAME}.paf" "$REF1_NAME" \
  "${OUT}/contigs_vs_${REF2_NAME}.paf" "$REF2_NAME" \
  "$ASM" "$OUT"

log "=== Step 2: read-level species fraction ==="
run_or_fail "minimap2 reads vs $REF1_NAME" bash -c \
  "minimap2 -ax map-ont -t $THREADS '$REF1' '$FILT' 2>'${OUT}/reads_vs_${REF1_NAME}.log' | samtools view -b -F 0x904 - > '${OUT}/reads_vs_${REF1_NAME}.bam'"
run_or_fail "minimap2 reads vs $REF2_NAME" bash -c \
  "minimap2 -ax map-ont -t $THREADS '$REF2' '$FILT' 2>'${OUT}/reads_vs_${REF2_NAME}.log' | samtools view -b -F 0x904 - > '${OUT}/reads_vs_${REF2_NAME}.bam'"

R1_READS=$(samtools view -c "${OUT}/reads_vs_${REF1_NAME}.bam")
R2_READS=$(samtools view -c "${OUT}/reads_vs_${REF2_NAME}.bam")
TOTAL_READS=$(python3 -c "
import csv
with open('${SDIR}/qc/seqkit_stats_filtered.tsv') as f:
    row = next(csv.DictReader(f, delimiter='\t'))
    print(row['num_seqs'].replace(',', ''))
")

echo -e "reference\tprimary_mapped_reads\tfraction_of_total" > "${OUT}/read_species_fraction.tsv"
echo -e "${REF1_NAME}\t${R1_READS}\t$(python3 -c "print(f'{${R1_READS}/${TOTAL_READS}:.3f}')")" >> "${OUT}/read_species_fraction.tsv"
echo -e "${REF2_NAME}\t${R2_READS}\t$(python3 -c "print(f'{${R2_READS}/${TOTAL_READS}:.3f}')")" >> "${OUT}/read_species_fraction.tsv"
log "Total filtered reads: $TOTAL_READS"
cat "${OUT}/read_species_fraction.tsv"

log "=== Step 3: BUSCO on each contig bin ==="
for name in "$REF1_NAME" "$REF2_NAME"; do
  BIN_FA="${OUT}/contigs_${name}.fasta"
  if [[ -s "$BIN_FA" ]]; then
    if ! compgen -G "${OUT}/busco_${name}/short_summary*.txt" > /dev/null; then
      run_or_fail "busco on ${name} bin" busco -i "$BIN_FA" -o "busco_${name}" \
        --out_path "$OUT" -l "$BUSCO_LINEAGE_PRIMARY" -m genome -c "$THREADS" \
        --download_path "$BUSCO_DL_DIR" -f
    fi
  else
    log "No contigs assigned to $name, skipping BUSCO"
  fi
done

log "Investigation complete. See ${OUT}/ for contig_bins.tsv, read_species_fraction.tsv, busco_*/"
