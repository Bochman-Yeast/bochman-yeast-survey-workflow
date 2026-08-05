#!/bin/bash
# Shared helpers. Source this; do not execute directly.

log() {
  # Writes to stderr, not stdout: several call sites (e.g. 04_ani_analysis.sh's
  # download_ref_for_species) capture a function's stdout via command
  # substitution to get its real return value - log output must not land there.
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts]${SAMPLE:+ [$SAMPLE]} $*" >&2
}

# usage: skip_if_done <marker_file_or_glob> <description>
# returns 0 (true) if already done and caller should skip
skip_if_done() {
  local marker="$1" desc="$2"
  if [[ -s "$marker" ]]; then
    log "SKIP (already done): $desc [$marker]"
    return 0
  fi
  return 1
}

# usage: run_or_fail <description> <command...>
# logs start/end/failure; on failure, records to FAILURES.tsv but does NOT
# exit the script - caller decides whether the failure is fatal for this sample.
run_or_fail() {
  local desc="$1"; shift
  log "START: $desc"
  local start_ts=$SECONDS
  if "$@"; then
    log "OK: $desc ($((SECONDS-start_ts))s)"
    return 0
  else
    local rc=$?
    log "FAIL (rc=$rc): $desc"
    mkdir -p "$RESULTS_DIR"
    echo -e "$(date '+%F %T')\t${SAMPLE:-NA}\t$desc\trc=$rc" >> "${RESULTS_DIR}/FAILURES.tsv"
    return $rc
  fi
}

echo_versions() {
  log "=== tool versions ==="
  for t in seqkit NanoPlot chopper flye busco barrnap ITSx blastn skani datasets; do
    if command -v "$t" >/dev/null 2>&1; then
      local ver
      ver=$("$t" --version 2>&1 | head -1)
      log "  $t: $ver"
    else
      log "  $t: NOT FOUND"
    fi
  done
}
