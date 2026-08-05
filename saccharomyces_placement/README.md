# Saccharomyces Population Placement — Paper 2, Zenodo Component

Placement of five wild *S. cerevisiae* isolates (YH123, YH166, YH196, YH229, DoF1) within the
3,034-genome population panel of Loegler, Friedrich & Schacherer (2024, *G3* 14(12):jkae245),
plus the superclade allele-sharing analysis for YH166, the fine-clade assignment for YH229, and
supporting heterozygosity/private-variant and CNV/aneuploidy analyses.

## This placement is independent of the (withdrawn) *S. eubayanus* introgression screen

**This directory does not contain, and is not affected by, the interspecies-introgression
screen for YH166/YH229.** An initial apparent *S. eubayanus* signal for those two isolates was
investigated in depth and withdrawn — it was determined to be a competitive-mapping artifact, not
genuine interspecies ancestry. YH166 and YH229 are wild, beer-associated *S. cerevisiae* with no
detectable *S. eubayanus* introgression (both carry *S. cerevisiae*-type mitochondria and
2-micron plasmids; a whole-assembly chimeric-junction scan found zero *S. cerevisiae*/
*S. eubayanus* junctions in either isolate).

The withdrawal investigation, its controls, and its evidence are packaged **separately**, as
part of the FIDDL toolkit deposit — not here. The placement, allele-sharing, and fine-clade
results in this directory are SNP/panel-genotype-based, methodologically unrelated to that
screen, and unaffected by its outcome.

## Contents

```
saccharomyces_placement/
  environment.yml            # conda environment (yeast-id) used for this analysis
  placement/                 # panel alignment, per-isolate variant calls, FastTree placement -> Figure 2
  yh166_admixture/           # YH166 superclade allele-sharing analysis
  yh229_fine_clade/          # YH229 fine-clade assignment (12. Belgium Beer 1)
  supporting_analyses/       # heterozygosity/private-variant and CNV/aneuploidy analyses
```

## What's NOT included, and why

Large intermediate files that reconstruct into the final outputs kept here (panel-wide genotype
extracts, genome-wide read-depth scans, a per-isolate panel-VCF subset used only to compute the
YH166 allele-sharing numbers) are excluded — they are regenerable from the panel's own public
Zenodo deposit (10.5281/zenodo.12580561, 10.5281/zenodo.12571280) plus the scripts included here,
and were judged not worth the bandwidth for a public deposit. The source population panel's own
supplementary data file (`jkae245_supplementary_data.zip`) is likewise excluded — it is the
panel paper's own copyrighted material; cite it directly rather than redistributing it here.

## Reproducing the key numbers from saved output (no re-computation needed)

- YH166 allele-sharing: `yh166_admixture/allele_sharing_table.tsv` (derived from `yh166_deep.out`)
- YH229 fine-clade: `yh229_fine_clade/annotate_neighbors.out`
- Both independently verified against the manuscript's cited text (exact match, no discrepancies).

## Source panel citation

Loegler V, Friedrich A, Schacherer J. Overview of the *Saccharomyces cerevisiae* population
structure through the lens of 3,034 genomes. *G3* 2024;14(12):jkae245. doi:10.1093/g3journal/jkae245
