#!/bin/bash
# Run this BEFORE attempting Clair3 calls - we need to know which bundled ONT
# basecaller model matches the Plasmidsaurus data (Q20=94%/Q30=81% on raw reads
# suggests R10.4.1 chemistry with sup/hac basecalling, but don't assume - check
# what's actually bundled and cross-reference against any run metadata available).
source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id
set -euo pipefail

echo "=== Clair3 version ==="
run_clair3.sh --version 2>&1 || true

echo ""
echo "=== Bundled models available in this install ==="
CLAIR3_ENV=$(dirname "$(dirname "$(command -v run_clair3.sh)")")
find "$CLAIR3_ENV" -maxdepth 4 -ipath "*models*" -type d 2>/dev/null

echo ""
echo "=== If nothing obviously matches R10.4.1 sup/hac, check for any Plasmidsaurus"
echo "    run report / basecaller version info that may have shipped with the raw data ==="
find /N/scratch/bochman/yeast_id -iname "*sequencing_summary*" -o -iname "*run_report*" -o -iname "*basecall*" 2>/dev/null | head -20
