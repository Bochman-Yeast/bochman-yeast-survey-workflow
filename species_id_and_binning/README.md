# species_id_and_binning

Wild-yeast species identification for 9 Nanopore-sequenced isolates, plus
two follow-up investigations that required going beyond the automated
pipeline. Part of a larger combined deposit for Paper 2; this package
covers three of that paper's seven analysis areas:

1. **Species-ID decision pipeline** — ITS/D1-D2-LSU rDNA barcode screening
   (remote BLAST vs. `nt`) plus whole-genome ANI (`skani`) confirmation,
   authoritative for disambiguating *Saccharomyces* sensu stricto, where
   the barcode alone cannot resolve species. Produces `results/summary.tsv`
   and `results/REPORT.md` — the source of every per-isolate call number in
   the manuscript.
2. **YH140 co-culture resolution** (`yh140_coculture/`) — one isolate's
   assembly turned out to be a genuine two-species co-culture rather than a
   single organism; resolved by competitive reference alignment, confirmed
   independently by read-fraction mapping, per-bin BUSCO, and coverage/GC
   separation. See `yh140_coculture/README.md`.
3. **YH156 species re-identification, verification half** (`yh156_verification/`)
   — an isolate initially mis-called as *S. japonicus* by a separate
   reassembly effort; this package's contribution is the independent ANI
   verification that refuted that call and confirmed the correct species
   (*S. versatilis*, nom. inval.). The reassembly itself is a separate
   package. See `yh156_verification/README.md`.

## How to run

Environment: `conda env create -f environment.yml` (channels: conda-forge,
bioconda, `channel_priority: strict`). See "Dependency versions" below for
exactly what was used to produce the published numbers.

The pipeline expects a directory layout with raw FASTQ under `data/raw/`
and a `samples.tsv` sample sheet (`pipeline/scripts/00_make_sample_sheet.sh`
generates one from a directory of FASTQ files). Per-sample steps, in order:

```
pipeline/scripts/02_per_sample_qc_assemble.sh <sample>   # QC, filter, assemble, BUSCO, rRNA markers
pipeline/scripts/03_remote_blast.sh                       # barcode BLAST, all samples (sequential, rate-limited)
pipeline/scripts/04_ani_analysis.sh <sample>               # reference download + skani ANI
python3 pipeline/scripts/05_consensus_report.py             # aggregate -> results/summary.tsv, REPORT.md
```

Slurm submission wrappers for each step are in `pipeline/slurm/` (written
for a specific HPC account/partition — edit the `#SBATCH` headers before
reuse elsewhere).

For an isolate whose assembly turns out to be a candidate mixed culture
(discordant ITS/LSU barcode identities and/or an oversized assembly), run
`pipeline/scripts/investigate_mixed_sample.sh <sample> <ref1.fna> <ref2.fna>`
— see `yh140_coculture/README.md` for the full method and how its output
feeds back into `05_consensus_report.py`.

**Before trusting a BUSCO score for a non-Saccharomycetes isolate**, read
"Known limitations" below — the automated pipeline will not catch a
lineage mismatch on its own.

## Dependency versions

Versions actually used to produce the published results (confirmed via
tool-version log output captured during the real pipeline runs, not
assumed from `environment.yml`'s version pins alone):

| Tool | Version | Notes |
|---|---|---|
| NanoPlot | 1.47.1 | |
| chopper | 0.13.0 | |
| Flye | 2.9.6-b1802 | `--nano-hq` mode |
| BUSCO | 5.8.3 | gene predictor auto-selected as miniprot 0.18-r281; hmmsearch 3.4 |
| barrnap | 1.10.5 | `--kingdom fun` — this build's catalog supports only bac/arc/fun, not a generic eukaryote model |
| ITSx | 1.1.3 | |
| skani | 0.3.2 | `-s 70 --slow`, not defaults — see bugfix note below |
| minimap2 | 2.31-r1302 | used in YH140 co-culture binning |
| NCBI `datasets` CLI | 18.32.0 | |
| seqkit | `[version not found]` — pinned as `seqkit=2.*`; installed build has no working `--version` flag |
| blastn (BLAST+) | `[version not found]` — installed build does not print a clean version string via `--version` |
| samtools | `[version not found]` — never queried |

**Three real bugs were found and fixed during development; all three are
in the code in this package, with one exception (see Known Limitations):**
1. skani's default screening threshold (`-s 80`) silently drops valid
   but more-divergent reference comparisons with no error — fixed with
   `-s 70 --slow` in `pipeline/scripts/04_ani_analysis.sh`.
2. BLAST hits from non-taxonomic `nt` records (PDB structures, "Uncultured
   ...", "Mutant ..." strain descriptions) were being misread as species
   names — fixed with a binomial-name validator in
   `pipeline/scripts/pick_candidate_species.py` and
   `pipeline/scripts/05_consensus_report.py`.
3. BUSCO lineage mismatch for non-Saccharomycetes isolates — **not fixed
   in code**, only manually corrected for the two affected isolates. See
   below.

## Known limitations

**BUSCO lineage selection does not auto-detect a mismatch — only an
outright failure.** `pipeline/scripts/02_per_sample_qc_assemble.sh` (lines
56–67) runs BUSCO against `BUSCO_LINEAGE_PRIMARY` (`saccharomycetes_odb10`)
for every isolate, and only falls back to `BUSCO_LINEAGE_FALLBACK`
(`fungi_odb10`) when BUSCO **errors out**. It does not check whether the
resulting completeness score is plausible, and it has no logic to detect
that an isolate belongs to a different fungal class than the one
`saccharomycetes_odb10` is calibrated for.

This is not a hypothetical gap — it already happened, twice, in this
project. Two isolates (**YH115**, *Schizosaccharomyces pombe*, and
**YH156**, *Schizosaccharomyces versatilis*) belong to class
Schizosaccharomycetes, not Saccharomycetes. Scored against the default
`saccharomycetes_odb10` lineage, YH115 returned a misleadingly low 61.3%
completeness — not because the assembly was incomplete, but because the
benchmark itself was wrong for this organism. The pipeline's fallback logic
never triggered, because BUSCO did not error — it ran to completion and
produced a valid-looking, but misleading, low number.

The correct lineage (`ascomycota_odb10` — the broadest lineage with actual
BUSCO coverage of Schizosaccharomycetes, since no dedicated
Schizosaccharomycetes/Taphrinomycotina lineage dataset exists in the
current BUSCO catalog) was applied **manually**, per isolate, after a human
noticed the implausible score in light of other evidence (barcode/ANI
results placing these isolates well outside Saccharomycetes). The corrected
output was then substituted into `results/` in place of the mismatched run
so that downstream reporting (`05_consensus_report.py`) picks it up
automatically. The exact commands used are documented, runnable, in
[`busco/manual_lineage_correction.sh`](busco/manual_lineage_correction.sh).

**This affects reproducibility going forward.** Running this pipeline
end-to-end on any future non-Saccharomycetes isolate will silently repeat
the same failure mode: BUSCO will complete without error, report a low
completeness score, and nothing in the pipeline will flag that the
*lineage*, not the *assembly*, is the problem. A human must manually check
whether a low BUSCO score correlates with an isolate that barcode/ANI
evidence places outside Saccharomycetes, and apply the correction in
`busco/manual_lineage_correction.sh` by hand if so. This pass does not
change the pipeline's trigger logic — the gap is documented, not fixed.
