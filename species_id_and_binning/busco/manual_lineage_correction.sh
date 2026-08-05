#!/bin/bash
# Manual BUSCO lineage correction for non-Saccharomycetes isolates.
#
# WHY THIS EXISTS: pipeline/scripts/02_per_sample_qc_assemble.sh (lines
# 56-67) only falls back from BUSCO_LINEAGE_PRIMARY (saccharomycetes_odb10)
# to BUSCO_LINEAGE_FALLBACK (fungi_odb10) when BUSCO errors out outright.
# It does NOT detect a merely-low completeness score caused by scoring an
# isolate against a taxonomically inappropriate lineage. This is a known,
# unfixed gap in the automated pipeline (see README.md "Known limitations").
#
# This script is NOT part of the automated pipeline and is NOT invoked by
# it. It documents, exactly, the manual commands actually run on Quartz to
# correct two isolates (YH115, YH156) whose default saccharomycetes_odb10
# BUSCO score was misleadingly low because both belong to class
# Schizosaccharomycetes, not Saccharomycetes. Run by hand, per-isolate,
# only when you have independent reason to suspect a lineage mismatch
# (e.g. a barcode/ANI result placing the isolate outside Saccharomycetes
# alongside an implausibly low BUSCO score).
#
# Both commands below were run via `sbatch --wrap`, not `srun --pty`
# interactively - an earlier interactive attempt for YH156 was lost when
# the SSH session disconnected, since srun --pty jobs die with the
# terminal. sbatch detaches from the terminal and survives disconnection.
set -uo pipefail
cd /N/scratch/$USER/yeast_id

# ---------------------------------------------------------------------
# Case 1: YH115 - Schizosaccharomyces pombe
# The DEFAULT pipeline already ran BUSCO against saccharomycetes_odb10
# for this isolate (that's what the automated pipeline always does) and
# produced a misleadingly low 61.3% completeness at results/YH115/busco/.
# Steps: re-run against the correct lineage, then swap the corrected
# result into the path 05_consensus_report.py actually reads from.
# ---------------------------------------------------------------------

sbatch -A r02049 -p debug -t 45:00 -c 8 --mem=64G --wrap="\
source /N/u/$USER/Quartz/miniconda3/etc/profile.d/conda.sh && \
conda activate yeast-id && \
busco -i results/YH115/assembly/assembly.fasta -o busco_ascomycota \
  --out_path results/YH115 -l ascomycota_odb10 -m genome -c 8 \
  --download_path busco_downloads -f"

# Wait for the job to complete (squeue -u $USER), then:
mv results/YH115/busco results/YH115/busco_saccharomycetes_MISMATCHED_LINEAGE
mv results/YH115/busco_ascomycota results/YH115/busco
# The mismatched run is archived, not deleted, for transparency. After
# this swap, 05_consensus_report.py's read_busco_complete() (which just
# globs results/<isolate>/busco/short_summary*.txt) picks up the
# corrected 80.0% value automatically on the next report regeneration -
# no code change needed for THIS already-affected isolate, only for the
# general case (see README "Known limitations").
#
# Note on resourcing: an earlier attempt at 16GB was OOM-killed partway
# through the miniprot alignment step; ascomycota_odb10 has a larger
# marker set (1706 BUSCOs) than saccharomycetes_odb10 (2137 BUSCOs, but
# apparently a lighter memory footprint in practice) and needs more
# headroom. 64GB completed successfully in ~13 minutes.

# ---------------------------------------------------------------------
# Case 2: YH156 - Schizosaccharomyces versatilis (nom. inval.)
# This isolate's DEFAULT pipeline assembly (426 kb, 54 contigs) was a
# separate assembly failure (Flye coverage-filter artifact, unrelated to
# the BUSCO lineage issue) - see manual_note.txt for that story. The
# ascomycota_odb10 run below was against the reassembled draft from a
# separate investigation, run directly with the correct lineage from the
# start - there was no prior wrong-lineage run at this specific path to
# swap out.
# ---------------------------------------------------------------------

sbatch -A r02049 -p debug -t 45:00 -c 8 --mem=64G --wrap="\
source /N/u/$USER/Quartz/miniconda3/etc/profile.d/conda.sh && \
conda activate yeast-id && \
busco -i results/YH156/assembly_v3_canu_draft/assembly.fasta -o busco_ascomycota \
  --out_path results/YH156/assembly_v3_canu_draft -l ascomycota_odb10 -m genome -c 8 \
  --download_path busco_downloads -f"

# No swap needed for this case - output lands directly at
# results/YH156/assembly_v3_canu_draft/busco_ascomycota/, which is where
# the YH156 verification package (this session's Area 3) reads it from.
# Result: 75.8% complete (C:75.8%[S:72.6%,D:3.2%]).
