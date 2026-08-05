#!/bin/bash
# Sourced by every script. Edit paths/params here, not in individual scripts.
set -uo pipefail

# --- cluster ---
export SLURM_ACCOUNT="r02049"
export SLURM_PARTITION="general"
export SLURM_DEBUG_PARTITION="debug"

# --- paths (project root lives on scratch: big, not quota-limited like home) ---
export ROOT="/N/scratch/${USER}/yeast_id"
export RAW_DIR="${ROOT}/data/raw"
export RESULTS_DIR="${ROOT}/results"
export REFS_DIR="${ROOT}/refs"
export LOG_DIR="${ROOT}/logs"
export SAMPLE_SHEET="${ROOT}/samples.tsv"
export BUSCO_DL_DIR="${ROOT}/busco_downloads"

# --- QC/filter params ---
export MIN_Q=10
export MIN_LEN=1000
export THREADS="${SLURM_CPUS_PER_TASK:-16}"
export GENOME_SIZE_HINT="12m"

# --- BUSCO ---
export BUSCO_LINEAGE_PRIMARY="saccharomycetes_odb10"
export BUSCO_LINEAGE_FALLBACK="fungi_odb10"

# --- barcode call thresholds ---
export MIN_PIDENT=90.0
export MIN_QCOV=80.0

# --- ANI ---
export ANI_SPECIES_BOUNDARY=95

# Saccharomyces sensu stricto: barcode (ITS/D1D2) cannot separate these.
# Any sample whose barcode hits land in this genus gets ANI'd against ALL of
# these references, not just the top barcode hit's species - that's the
# whole point of the ANI step for this clade.
export SENSU_STRICTO_SPECIES=(
  "Saccharomyces cerevisiae"
  "Saccharomyces paradoxus"
  "Saccharomyces mikatae"
  "Saccharomyces kudriavzevii"
  "Saccharomyces arboricola"
  "Saccharomyces eubayanus"
  "Saccharomyces uvarum"
  "Saccharomyces jurei"
)

mkdir -p "$RAW_DIR" "$RESULTS_DIR" "$REFS_DIR" "$LOG_DIR" "$BUSCO_DL_DIR"
