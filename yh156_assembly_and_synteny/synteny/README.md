# Whole-genome structural comparison (Figure 3, Figure S2, Table S3)

Pipeline: minimap2 alignment for chromosome-assignment -> custom Biopython script builds
one pseudo-chromosome per reference chromosome from the (non-scaffolded, 213-contig)
draft, preserving native contig orientation except reverse-complementing individual
contigs to their own dominant alignment strand -> nucmer/delta-filter/show-coords ->
SyRI -> plotsr.

**Four canonical scripts, not one** — the pipeline has four distinct steps and no single
script reproduces all of them:
- `build_and_run_syri_sv.sbatch` — pseudo-chromosome construction + nucmer alignment
  (succeeded) + first SyRI attempt (failed, see below)
- `rerun_syri_only.sbatch` — the SyRI call that actually succeeded, reusing the
  alignment output from the script above
- `run_plotsr.sbatch` — synteny figure generation (`YH156_vs_sversatilis_synteny.png`)
- `check_boundary_artifacts.sbatch` — contig-boundary artifact check (see below)

**Version-compatibility troubleshooting (see the two retained failure logs,
`syri_sv_9656906.log` and `syri_sv2_9657652.log`, for full detail):** SyRI 1.7.1 crashed
under numpy 2.x (`ValueError: buffer source array is read-only`, a Cython/numpy-2
incompatibility) and, after a numpy downgrade did not fix it, under pandas >=2's
Copy-on-Write default (the actual fix was downgrading pandas to 1.5.3). `plotsr` 1.1.1
separately required matplotlib <=3.7 (newer matplotlib removed an internal API `plotsr`
depends on). See `../environment.yml` for the resolved, working version set.

## Results
- `YH156_sv_syri.out` / `.summary` / `.vcf` / `.log` — full SyRI output; `.summary` has
  the genome-wide category counts (99 syntenic regions, 13 inversions, 103
  translocations, etc.)
- `YH156_vs_sversatilis_synteny.png` — Figure 3
- `dechim_vs_sv.paf`, `sv_merged.bed` — chromosome coverage (93.7%/93.7%/94.3%,
  chr1/chr2/chr3)
- `boundary_check_9658505.log` — contig-junction artifact check; confirms the three
  headline events are not junction-adjacent artifacts

## Three headline structural events (Table S3)
| Event | Chromosome | Ref coords | Size |
|---|---|---|---|
| INV101 | chr1 (CP130697.1) | 2,162,341-2,930,379 | 768,038 bp |
| INV107 | chr2 (CP130698.1) | 6,024,352-6,319,603 | 295,251 bp |
| INV108 | chr2 (CP130698.1) | 6,343,879-6,458,904 | 115,025 bp |
| TRANS158 | chr3 (CP130699.1), intra-chr | 3,174,261-3,530,982 | 356,721 bp |

Note: chr2 is 7,341,441 bp in this reference (not the ~4.5 Mb typical of *S. pombe*) —
coordinates above 6 Mb on chr2 are correct, per-chromosome coordinates, not cumulative.

## Chromosome-2 repeat resolution
`run_blastx_te.sbatch` — BLASTx of representative repeat-region windows against nr
(Fungi-restricted) identified homology to Tf1/Tf2-type LTR retrotransposon polyproteins
(*S. pombe*), resolving the complex duplication/translocation signal at chr2
~2.4-5.5 Mb as real dispersed repeat content, not an assembly artifact. Output not
separately saved as a file in this package beyond the sbatch script; results are: hit to
"Transposon Tf1-107 polyprotein" (sp|Q01910.1, 38.997% identity, e=2.16e-159) and
"retrotransposable element/transposon Tf2-type" (ref|NP_001018800.2, 34.847%,
e=6.05e-159).

## alignment_intermediates/
Not directly cited in the manuscript; retained so the SyRI/plotsr step can be rerun
without repeating the nucmer alignment from scratch.
