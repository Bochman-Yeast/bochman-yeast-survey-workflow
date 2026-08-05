# BUSCO three-way comparison (Figure S1)

Three runs, identical settings (BUSCO 5.8.3, lineage `ascomycota_odb12.2`, `--metaeuk`
gene predictor, `--offline`):

| Directory | Genome scored | Result |
|---|---|---|
| `busco_medaka_polished/` | YH156 corrected draft | C:55.4%[S:52.8%,D:2.5%],F:7.5%,M:37.1%,n:2557 |
| `busco_reference_control/` | *S. japonicus* GCF_000149845.2 (wrong-species control) | C:57.1%[S:54.1%,D:2.9%],F:7.8%,M:35.1%,n:2557 |
| `busco_reference_control_sversatilis/` | *S. versatilis* CBS 103 GCA_032882995.1 (correct-species control) | C:57.9%[S:54.9%,D:3.0%],F:7.5%,M:34.6%,n:2557 |

**Argument:** the draft's completeness is statistically indistinguishable from either
finished reference genome's own score — the ~55-58% ceiling on this lineage is a
property of the `ascomycota_odb12.2` ortholog database's fit to this early-diverging
taxon, not an assembly defect.

**Included: short summaries only (`.txt`/`.json`), not the full per-gene run
directories.** The three full `run_ascomycota_odb12.2/` output directories total 5.4 GB
combined (2.2G + 2.1G + 1.1G) — the full per-gene output is reproducible by rerunning the
documented BUSCO command (`environment.yml` + the settings above) rather than shipping it.
