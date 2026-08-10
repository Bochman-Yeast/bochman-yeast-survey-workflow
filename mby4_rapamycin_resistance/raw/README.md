# raw/ — MBY4 input reads and QC

## Inputs (not committed to git — see repo `.gitignore`)
- `MBY4.fastq.gz` — raw Plasmidsaurus Nanopore reads. Stage at
  `/N/scratch/bochman/mby4_rapamycin/raw/MBY4.fastq.gz` (or update the sbatch script paths
  to match wherever it actually lands).
- If Plasmidsaurus also delivered a draft assembly and/or BAM, keep them here as
  `plasmidsaurus_draft_assembly.fasta` / `plasmidsaurus.bam` — sanity-check references only,
  not used as the primary assembly (the pipeline assembles from raw reads independently in
  `../assembly/`).
- Check the Plasmidsaurus delivery README/report for the **basecaller and model used**
  (e.g. `dna_r10.4.1_e8.2_400bps_sup@v5.0.0`) — this determines the Flye mode
  (`--nano-raw` vs `--nano-hq`) and minimap2 preset (`map-ont` vs `lr:hq`) used downstream.
  Record it in `../NOTES.md` before running `run_nanoplot.sbatch` interpretation or
  `../assembly/run_flye.sbatch`.

## Step 1 — QC

`run_nanoplot.sbatch` runs NanoPlot on the raw FASTQ. Report (and log in `../NOTES.md`):
- Read N50
- Mean read length
- Mean read quality (Q)
- Total yield (bp)
- Estimated coverage = yield / 12,157,105 bp (S288c R64 genome size, standard reference
  point for yeast coverage estimates)

Flag before proceeding to assembly if: estimated coverage is low relative to what
long-read assembly typically wants (well below ~30-40x would be a concern for a 12 Mb
genome), read N50 is unexpectedly short, or mean quality looks inconsistent with the stated
basecaller model.

**This is the check-in point specified in the original task — report these numbers and get
explicit confirmation before running `../assembly/run_flye.sbatch`.**
