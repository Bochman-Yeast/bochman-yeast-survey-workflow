#!/bin/bash
# NOTE: this script was originally authored directly on Quartz via heredoc
# during the session and was never saved to the local working scratchpad -
# this is a faithful reconstruction from the session's command/output record,
# not a copy of an original file. The filter expression and results below
# are exact (verified against the run's actual retention statistics), but
# treat this file as documentation-grade rather than a byte-identical copy
# of whatever was literally executed.
#
# Apply hard filters to the normalized joint-called VCF, using bcftools'
# native bias-annotation set (RPBZ, MQBZ) as the nearest available analogs
# to GATK's ReadPosRankSum/MQRankSum (the presumed basis of the source
# study's own filtering, which could not be replicated field-for-field).
#
# An earlier version of this filter also included a hard DP<=20000 cap,
# removed after diagnosing it as miscalibrated: the invented threshold sat
# BELOW the actual per-site depth median across 145 samples, causing ~96%
# over-filtering. The source study's own filter set has no DP cap, so
# removing it also better matches the original methodology.
set -euo pipefail

source ~/miniconda3/etc/profile.d/conda.sh
conda activate yeast-id

WORKDIR=/N/scratch/bochman/lachancea_pop
OUTDIR="$WORKDIR/joint_calls"
cd "$OUTDIR"

echo "=== Filtering to biallelic SNPs, then applying hard filters ==="
bcftools view -m2 -M2 -v snps joint_norm.vcf.gz -Ou \
  | bcftools filter -i 'QUAL>=30 && MQ>=40 && abs(MQBZ)<=12.5 && abs(RPBZ)<=8' \
    -Oz -o joint_filtered.vcf.gz
bcftools index -t joint_filtered.vcf.gz

echo ""
echo "=== Retention ==="
total=$(bcftools view -H joint_norm.vcf.gz | wc -l)
kept=$(bcftools view -H joint_filtered.vcf.gz | wc -l)
echo "Input (normalized, all record types): $total"
echo "Retained (filtered, biallelic SNPs): $kept"
python3 -c "print(f'Retention: {$kept/$total*100:.1f}%')"
echo "(Expected: 1,010,416 / 1,086,101 = 93.0%, vs. source study's own reported 93.9%)"
