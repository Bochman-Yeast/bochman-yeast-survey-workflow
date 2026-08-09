#!/bin/bash
# intersect_mby4_specific.sh — identify MBY4-specific variants.
#
# STATUS: untested template. DO NOT RUN as an sbatch job — bcftools isec is fast/light
# enough for an interactive or login-node run once both reference-based call sets exist.
#
# Logic: a variant called in MBY4-vs-S288c that is genuinely private to MBY4 (not just
# S288c/W303 background divergence) should NOT also appear, at the same coordinate, in a
# W303-vs-S288c comparison. We don't have a direct W303-vs-S288c call set in this pipeline,
# so we approximate it via `bcftools isec` between MBY4-vs-S288c and MBY4-vs-W303:
#
#   - MBY4-vs-S288c calls that ARE NOT also MBY4-vs-W303 calls at the same S288c coordinate
#     are the closest single-VCF-pair approximation to "not S288c/W303 background," but
#     this is an approximation, not exact: MBY4-vs-W303 uses W303 coordinates, not S288c
#     coordinates, so direct positional intersection across the two VCFs is NOT valid
#     without first lifting one call set into the other's coordinate space (or, more
#     robustly, calling variants of W303-vs-S288c directly and subtracting that set from
#     MBY4-vs-S288c instead). **This coordinate-space mismatch must be resolved before
#     trusting this script's output — see the TODO below.** Document whichever approach is
#     actually used in ../../NOTES.md before reporting counts in SUMMARY.md.
#
# TODO before running for real: decide between (a) generating a W303-vs-S288c call set
# directly (map W303 assembly or reads to S288c, call variants, use that as the subtraction
# set against MBY4-vs-S288c — coordinate-compatible, more rigorous) or (b) some coordinate
# lift-over between S288c and W303 for the two-VCF approach sketched above. Log the decision
# in ../../NOTES.md.

set -euo pipefail

VARIANTS_DIR=/N/scratch/bochman/mby4_rapamycin/variants
SV_DIR=/N/scratch/bochman/mby4_rapamycin/sv
OUT_DIR=/N/scratch/bochman/mby4_rapamycin/results

bcftools --version | head -1

# --- SNVs/indels ---
bcftools sort -Oz -o $OUT_DIR/MBY4_vs_S288c.clair3.sorted.vcf.gz \
  $VARIANTS_DIR/MBY4_vs_S288c_clair3/merge_output.vcf.gz
bcftools sort -Oz -o $OUT_DIR/MBY4_vs_W303.clair3.sorted.vcf.gz \
  $VARIANTS_DIR/MBY4_vs_W303_clair3/merge_output.vcf.gz
bcftools index -t $OUT_DIR/MBY4_vs_S288c.clair3.sorted.vcf.gz
bcftools index -t $OUT_DIR/MBY4_vs_W303.clair3.sorted.vcf.gz

bcftools isec -p $OUT_DIR/snv_isec \
  $OUT_DIR/MBY4_vs_S288c.clair3.sorted.vcf.gz \
  $OUT_DIR/MBY4_vs_W303.clair3.sorted.vcf.gz

echo "--- raw MBY4-vs-S288c SNV/indel count ---"
zcat $VARIANTS_DIR/MBY4_vs_S288c_clair3/merge_output.vcf.gz | grep -vc '^#'
echo "--- MBY4-vs-S288c-private SNV/indel count (0000.vcf = S288c-only records) ---"
grep -vc '^#' $OUT_DIR/snv_isec/0000.vcf

# --- SVs (same coordinate-space caveat applies) ---
bcftools sort -Oz -o $OUT_DIR/MBY4_vs_S288c.sniffles.sorted.vcf.gz $SV_DIR/MBY4_vs_S288c.sniffles.vcf
bcftools sort -Oz -o $OUT_DIR/MBY4_vs_W303.sniffles.sorted.vcf.gz $SV_DIR/MBY4_vs_W303.sniffles.vcf
bcftools index -t $OUT_DIR/MBY4_vs_S288c.sniffles.sorted.vcf.gz
bcftools index -t $OUT_DIR/MBY4_vs_W303.sniffles.sorted.vcf.gz

bcftools isec -p $OUT_DIR/sv_isec \
  $OUT_DIR/MBY4_vs_S288c.sniffles.sorted.vcf.gz \
  $OUT_DIR/MBY4_vs_W303.sniffles.sorted.vcf.gz

echo "--- raw MBY4-vs-S288c SV count ---"
grep -vc '^#' $SV_DIR/MBY4_vs_S288c.sniffles.vcf
echo "--- MBY4-vs-S288c-private SV count ---"
grep -vc '^#' $OUT_DIR/sv_isec/0000.vcf
