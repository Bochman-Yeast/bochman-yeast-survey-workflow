# YH229 Fine-Clade Assignment

SNP/panel-genotype-based, methodologically independent of the withdrawn *S. eubayanus*
interspecies screen (see top-level README) — this result stands on its own.

## Method

For each study isolate, nearest-neighbor tips in the FastTree placement (`placement/combined_tree.nwk`)
were examined at two successively broader radii (immediate sister clade, then grandparent) using
BioPython's `Phylo.get_path()`/`get_terminals()`, and cross-referenced against the panel's
clade/superclade metadata to determine the modal clade among neighbors at each radius.

## Result for YH229

- Immediate-sister radius: 3/3 neighboring tips are **12. Belgium Beer 1**, FastTree support 1.0
- Grandparent radius: 4/4 neighboring tips are **12. Belgium Beer 1**, FastTree support 1.0

Both radii agree unanimously on the same clade at maximal FastTree support — a clean, unambiguous
fine-clade call. Reported node-support values are FastTree's local Shimodaira-Hasegawa-like
support statistic, not bootstrap percentages.

## Files

- `annotate_neighbors.out` — full nearest-neighbor breakdown for all 5 study isolates (YH229's
  result is one section within this shared output file)
- `scripts/annotate_neighbors.py` — the analysis script

## Validated against manuscript

Manuscript text (verified exact match): *"resolves at finer scale to a single, well-supported
sub-clade (12. Belgium Beer 1)."*
