# Distance metric

**Function:** `SNPRelate::snpgdsDiss()` — "individual dissimilarity analysis on genotypes"

**Basis:** average pairwise genotype-dosage difference (dosage coded 0/1/2 per
biallelic SNP) across all included sites, normalized to [0,1]. An IBS-based
genome-wide distance — smaller value = more genetically similar — though not
necessarily identical in exact formula to a literal "1 − IBS proportion" as
computed by other tools (e.g. PLINK). Serves the same purpose.

**Sites used:** 1,015,261 SNPs (22,562 monomorphic sites excluded from the
merged 148-sample set by SNPRelate automatically before computing dissimilarity)

**Samples:** 148 (145 published panel + YH26, YH72, YH140)

**Source:** computed in-memory by `placement_reconstructed/bionj_tree/13_build_tree.R`
(the same distance matrix feeds both the BIONJ tree and the printed
nearest-neighbor summary). The matrix itself was never written to disk as a
standalone file — the values in `pairwise_distances.tsv` are the derived
output SNPRelate/the script printed, preserved from
`/N/scratch/bochman/lachancea_pop/logs/tree_9718640.out` on Quartz.
