#!/bin/bash
# Per-sample: pick candidate species from barcode hits, download reference
# genome(s), run skani for whole-genome ANI.
#
# Saccharomyces sensu stricto special case: barcode hits cannot distinguish
# S. cerevisiae / paradoxus / mikatae / kudriavzevii / arboricola / eubayanus /
# uvarum / jurei, so ANY sample whose barcode candidates land in that genus
# gets ANI'd against the FULL reference panel, not just the top barcode hit.
#
# Reference downloads are cached under $REFS_DIR and shared across samples,
# guarded with flock so concurrent array tasks don't race on the same download.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/config.sh"
source "$DIR/scripts/lib.sh"

SAMPLE="${1:?Usage: 04_ani_analysis.sh <sample>}"
SDIR="${RESULTS_DIR}/${SAMPLE}"
mkdir -p "${SDIR}/ani" "${SDIR}/logs"
exec > >(tee -a "${SDIR}/logs/04_ani.log") 2>&1
echo_versions

ASM="${SDIR}/assembly/assembly.fasta"
[[ -s "$ASM" ]] || { log "FATAL: no assembly for $SAMPLE"; exit 1; }

MIN_PIDENT="$MIN_PIDENT" MIN_QCOV="$MIN_QCOV" python3 "$DIR/scripts/pick_candidate_species.py" \
  "${SDIR}/blast/ITS.blast.tsv" "${SDIR}/blast/LSU_D1D2.blast.tsv" \
  > "${SDIR}/ani/candidate_species.txt" || true

mapfile -t CANDIDATES < "${SDIR}/ani/candidate_species.txt"
if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
  log "No candidate species parsed from BLAST hits; skipping ANI for $SAMPLE"
  exit 0
fi

IS_SENSU_STRICTO=0
for c in "${CANDIDATES[@]}"; do
  [[ "$c" == "Saccharomyces "* ]] && IS_SENSU_STRICTO=1
done

REF_LIST="${SDIR}/ani/ref_list.txt"
> "$REF_LIST"

download_ref_for_species() {
  local species="$1"
  local key
  key=$(echo "$species" | tr ' ' '_' | tr -cd 'A-Za-z0-9_')
  local outdir="${REFS_DIR}/${key}"
  local lock="${REFS_DIR}/.${key}.lock"
  mkdir -p "$REFS_DIR"
  (
    flock -w 1800 200
    if [[ ! -s "${outdir}/genome.fna" ]]; then
      mkdir -p "$outdir"
      log "Downloading reference genome for: $species"
      acc=$(datasets summary genome taxon "$species" --reference --as-json-lines 2>/dev/null \
            | python3 -c "import sys,json
for l in sys.stdin:
    try: print(json.loads(l).get('accession',''))
    except Exception: pass" | head -1)
      if [[ -z "$acc" ]]; then
        log "No reference-flagged assembly for $species, trying best available"
        acc=$(datasets summary genome taxon "$species" --as-json-lines --limit 1 2>/dev/null \
              | python3 -c "import sys,json
for l in sys.stdin:
    try: print(json.loads(l).get('accession',''))
    except Exception: pass" | head -1)
      fi
      if [[ -n "$acc" ]]; then
        (cd "$outdir" && datasets download genome accession "$acc" --include genome --filename ncbi_dataset.zip \
          && unzip -o -q ncbi_dataset.zip \
          && find ncbi_dataset -name "*.fna" -exec cp {} genome.fna \;)
      else
        log "WARNING: could not resolve any assembly accession for $species"
      fi
    fi
  ) 200>"$lock"
  [[ -s "${outdir}/genome.fna" ]] && echo "${outdir}/genome.fna"
}

if [[ $IS_SENSU_STRICTO -eq 1 ]]; then
  log "Saccharomyces sensu stricto signal detected -> downloading full reference panel"
  for sp in "${SENSU_STRICTO_SPECIES[@]}"; do
    ref=$(download_ref_for_species "$sp")
    [[ -n "$ref" ]] && echo "$ref" >> "$REF_LIST"
  done
else
  for sp in "${CANDIDATES[@]}"; do
    ref=$(download_ref_for_species "$sp")
    [[ -n "$ref" ]] && echo "$ref" >> "$REF_LIST"
  done
fi

if [[ ! -s "$REF_LIST" ]]; then
  log "No reference genomes available for $SAMPLE; skipping skani"
  exit 0
fi

SKANI_OUT="${SDIR}/ani/skani_results.tsv"
if ! skip_if_done "$SKANI_OUT" "skani"; then
  # -s 70 (default 80) + --slow (default -c 125): default settings silently
  # drop reference pairs below skani's k-mer screening threshold with no
  # error - fine for within-species ANI but too aggressive for cross-species
  # comparisons like the Saccharomyces sensu stricto panel, where several
  # references sit in the 80-85% range and were getting dropped entirely.
  run_or_fail "skani" skani dist -q "$ASM" --rl "$REF_LIST" -t "$THREADS" -s 70 --slow -o "$SKANI_OUT"
fi

touch "${SDIR}/.step04.done"
log "ANI analysis complete for $SAMPLE."
