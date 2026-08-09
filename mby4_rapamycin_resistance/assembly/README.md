# assembly/ — MBY4 de novo assembly + polishing

**Do not run until step 1 (`../raw/`) QC has been reported and confirmed with the user** —
this is the explicit check-in point from the original task.

Pipeline, in order:
1. `run_flye.sbatch` — Flye de novo assembly. Mode (`--nano-raw` vs `--nano-hq`) depends on
   the basecaller/model used for MBY4's reads (see `../raw/README.md`) — **not yet chosen**,
   fill in once confirmed. `--nano-hq` is appropriate for modern high-accuracy
   (`sup`/`hac`, R10.4.1) basecalls; `--nano-raw` for older/lower-accuracy calls.
2. `medaka_polish.sbatch` — ONT-only consensus polishing (no Illumina data available for
   MBY4, per the original task). Model must match the actual basecaller/flow cell chemistry
   (see `medaka tools list_models`) — placeholder model name in the script is illustrative
   only, following the pattern used in `../../yh156_assembly_and_synteny/assembly/medaka_polish.sbatch`,
   and must be replaced with the correct one for MBY4's actual read data.

Report after running: total assembly size, contig count, N50. Flag if total size deviates
meaningfully from ~12.1 Mb (S288c reference size) — this early-stage signal (before any
depth-ratio analysis in `../asm_vs_asm/`) can already hint at aneuploidy.
