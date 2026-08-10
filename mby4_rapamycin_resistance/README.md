# MBY4 rapamycin resistance — genome comparison (pipeline scaffold, not yet run)

**Status: unexecuted scaffold.** Everything in this directory (sbatch scripts, environment
spec, NOTES.md template, results templates) was drafted in a cloud/GitHub-only Claude Code
session that has no access to IU Quartz, SLURM, `/N/scratch`, the MBY4 raw reads, or any
bioinformatics tools — see "How this scaffold was built" below. Nothing here has been run.
This package documents an intended pipeline, not a completed analysis. Do not cite any
number in this directory as a result until the actual Quartz run has happened and this
README has been rewritten to reflect it (following the pattern of `../yh156_assembly_and_synteny/`,
which documents a pipeline that *was* actually executed).

## Goal

Identify the genetic basis of rapamycin resistance in wild-type *S. cerevisiae* isolate
MBY4 (Plasmidsaurus Nanopore long reads), by comparing MBY4 against S288c (R64) and W303,
with a strong mechanistic prior on the TOR pathway (`FPR1`/FKBP12 loss-of-function, `TOR1`
FRB-domain missense, `TOR2`, `KOG1`/`LST8`/`TCO89`, PDR-family efflux transporters, and
copy-number gain at the `TOR1` locus).

## Why compare against both S288c and W303

S288c (GCF_000146045.2, R64) is the community reference and best-annotated genome, but it
differs from most lab working strains at ~9,500 sites affecting ~700 genes (Matheson et al.
2017, W303 characterization — see `reference/PROVENANCE.md`). If MBY4 descends from a
W303-like background rather than S288c, calling variants against S288c alone would surface
that entire W303-vs-S288c background-divergence set as false-positive "MBY4-specific"
candidates. Calling against W303 too, and subtracting, isolates variants that are
genuinely private to MBY4 (see `results/` filtering-stage counts, once populated).

## Directory structure

| Directory | Purpose |
|---|---|
| `reference/` | S288c (R64) and W303 reference genomes + `PROVENANCE.md` documenting accession choice |
| `raw/` | MBY4 Plasmidsaurus FASTQ (not committed — see `.gitignore` note below) + NanoPlot QC |
| `assembly/` | Flye de novo assembly + Medaka polishing of MBY4 |
| `mapping/` | minimap2 read alignments of MBY4 reads to S288c and to W303 |
| `variants/` | Clair3 small-variant (SNV/indel) calls, S288c and W303, separately |
| `sv/` | Sniffles2 structural-variant calls, S288c and W303, separately |
| `asm_vs_asm/` | Assembly-vs-assembly alignment (minimap2 asm5 / MUMmer dnadiff) for CNV/aneuploidy screening and SV cross-check |
| `results/` | Intersected MBY4-specific variant sets, TOR-pathway targeted lookup, SnpEff annotation, `SUMMARY.md` |
| `environment.yml` | Main conda env — QC/assembly/mapping/SV/annotation tools. **Versions proposed/typical, not confirmed on Quartz. Confirm before running (see file header).** |
| `environment_clair3.yml` | Separate conda env for Clair3 only — split out because its pinned pytorch/tensorflow stack tends to conflict with the main env's solve. |
| `NOTES.md` | Running log template — commands, tool versions, and decision points, to be filled in *during* the actual run, not reconstructed after |

## Sequencing data

MBY4 raw Nanopore FASTQ path was not supplied in the originating request (placeholder
`[PATH_TO_MBY4_FASTQ]`). Large FASTQ/BAM files should **not** be committed to this git repo
— stage them under `/N/scratch/bochman/mby4_rapamycin/raw/` on Quartz per the working
directory layout below, and record their provenance (Plasmidsaurus run ID, delivery date,
basecaller/model if stated in the delivery README) in `NOTES.md`. If Plasmidsaurus also
delivered a draft assembly or BAM, keep it as a sanity-check reference only — the pipeline
assembles from raw reads independently (see `assembly/README.md`, not yet written).

## Working directory on Quartz

All sbatch scripts in this package assume:

```
/N/scratch/bochman/mby4_rapamycin/
├── raw/
├── assembly/
├── mapping/
├── variants/
├── sv/
├── asm_vs_asm/
├── results/
└── NOTES.md
```

Adjust the `#SBATCH --output` and in-script paths if the actual run uses a different root.

## Open decision points that MUST be resolved before running (do not silently default)

1. ~~Basecaller model for MBY4 reads~~ — **RESOLVED** on Quartz 2026-08-09: confirmed
   directly from FASTQ read headers as `dna_r10.4.1_e8.2_400bps_sup@v4.3.0`. `assembly/`,
   `mapping/*.sbatch` updated accordingly (`--nano-hq`, `-ax lr:hq`). See `NOTES.md` for
   full detail. **Partially open:** the exact Medaka/Clair3 model-name strings
   (`r1041_e82_400bps_sup_v430`) are search-derived, not yet confirmed against this Quartz
   install's actual model lists — `assembly/medaka_polish.sbatch` and
   `variants/clair3_*.sbatch` both flag this and the latter auto-verifies at runtime.
2. ~~W303 reference accession~~ — **RESOLVED** on Quartz 2026-08-09: GCA_965282845.1, see
   `reference/PROVENANCE.md` for the full comparison and reasoning. Reference downloaded,
   staged at `reference/W303.fna`, headers renamed to `chrI`-`chrXVI`.
3. ~~TOR-pathway gene coordinates~~ — **RESOLVED** on Quartz 2026-08-09: all six genes'
   coordinates confirmed from the S288c GFF3 (GCF_000146045.2, the actual mapping reference,
   also downloaded and staged at `reference/S288c_R64.fna`), plus TOR1's FRB domain and
   S1972 resistance hotspot confirmed from UniProt P35169. See
   `results/tor_pathway_genes.tsv`.

## How this scaffold was built

Drafted in a Claude Code session running in a GitHub-connected cloud container (no SLURM,
no `/N/scratch`, no bioinformatics tools installed, no access to the MBY4 reads) in response
to a pipeline prompt written for an interactive Claude Code session on Quartz. Rather than
fabricate NanoPlot/Flye/Clair3/Sniffles2 output, this session built the directory structure,
sbatch script templates, environment spec, and results templates only, mirroring the
conventions already established in `../yh156_assembly_and_synteny/` (which documents a
pipeline that actually ran on Quartz under this same allocation, r02049). The actual
pipeline still needs to be run, checked in on at the QC-vs-assembly checkpoint as the
original prompt requested, and the results templates replaced with real output.
