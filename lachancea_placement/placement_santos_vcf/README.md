# Placement against the authoritative (Santos) VCF

Independent verification of the reconstructed-panel placement (see main
`README.md`), run against the source study's own filtered genotype matrix
once it was finally obtained.

**Contains:** ADMIXTURE (`admixture/`) and PCA (`pca/`) only.

**Does NOT contain a tree.** A BIONJ tree was attempted here
(`20_santos_build_tree.R`, not included in this package) using the same
fan/circular layout as the reconstructed-panel tree. It failed twice — the
circular layout rendered distorted both times, for reasons not fully
root-caused. A rectangular-layout fallback (`21_santos_build_tree_rect.R`,
also not included) was written but never executed before this branch of the
work was set aside. If a tree figure for this specific dataset is needed:

1. The underlying data (merged VCF, PLINK files, GDS file) should already
   exist on Quartz in `santos_placement/` — check before re-deriving anything.
2. `19_santos_pca.R` (included) already builds the same SNPRelate GDS file
   the tree would need (`combined.gds`) as a side effect of running PCA.
3. Start from the rectangular layout, not the fan layout — it's the style
   confirmed to render reliably elsewhere in this project.

**Result (both methods concordant with the reconstructed-panel placement):**

| Method | Result |
|---|---|
| Supervised ADMIXTURE (K=6) | 99.995% Canada-trees ancestry, all 3 isolates (YH26, YH72, YH140) |
| PCA (unsupervised) | Nearest to Canada-trees centroid; PC1=21.69%, PC2=19.38%, PC3=8.70% variance explained |

Referenced in the manuscript's Methods/Limitations as independent
confirmation that the reconstructed-panel placement (Figure 4, Figure S3)
is not an artifact of the reconstruction methodology.
