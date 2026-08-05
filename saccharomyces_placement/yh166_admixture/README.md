# YH166 Superclade Allele-Sharing Analysis

Intraspecies analysis (among *S. cerevisiae* panel superclades), SNP/panel-genotype-based, and
methodologically independent of the withdrawn *S. eubayanus* interspecies screen (see top-level
README) — this result stands on its own.

## What this shows

YH166's *S. cerevisiae* genotype does not resolve into any of the source panel's 39 named clades.
At YH166's 35,800 heterozygous SNP sites that are also documented in the panel catalog, this
analysis computes the mean alternate-allele frequency within each panel superclade — i.e., how
often each superclade's isolates already carry the same alt allele YH166 is heterozygous for.
The Asian Fermentation superclade shows the highest sharing (0.4625), consistent with (not proof
of) that lineage contributing to YH166's ancestry within *S. cerevisiae*. No superclade approaches
fixation (1.0), arguing against a clean two-superclade F1 cross — more likely an older or more
diluted admixture event.

## Files

- `allele_sharing_table.tsv` — the 5 per-superclade values (derived, clean tabular form)
- `yh166_deep.out` — raw script output (site-list construction + allele-sharing computation)
- `investigate_yh166.out` — nearest-neighbor tree-topology breakdown at 6 radii, plus origin
  metadata for YH166's closest panel neighbors (all individually unassigned/admixed isolates)
- `yh166_het_sites.tsv` — the 35,800-site list itself (YH166 heterozygous + panel-documented)
- `scripts/` — `yh166_site_list.py` (site-list construction), `yh166_allele_sharing.py`
  (allele-frequency computation), `investigate_yh166.py` (tree-neighbor analysis)

## Validated against manuscript

Manuscript text (verified exact match): *"a superclade-level allele-sharing analysis at YH166's
35,800 heterozygous sites shared with the panel catalog found the highest mean alternate-allele
frequency in the Asian Fermentation superclade (0.4625), followed by Wild (0.3606), Beer (0.3497),
Unassigned/Admixed (0.3247), and Wine (0.2935); no superclade approached fixation."*
