# *Lachancea thermotolerans* population placement

Phylogenomic placement of three wild-collected *L. thermotolerans* isolates
(YH26, YH72, and the *L. thermotolerans* component of YH140, a mixed culture
with *Torulaspora delbrueckii*) against the 145-strain published population
panel (six ecological/geographic clusters: Asia, Americas, Canada-trees,
Europe/Domestic-1, Europe/Domestic-2, Europe-Mix). All three isolates place
unambiguously in the **Canada-trees** cluster by every method used.

## Why the panel was reconstructed

The source study's own filtered genotype matrix (VCF) was not available when
this analysis began — the corresponding author offered to share it, but the
file transfer failed repeatedly across independent networks. Rather than
wait indefinitely, the population panel was reconstructed from the source
study's published raw reads: `reconstruction/` re-aligns and joint-calls all
145 published strains from scratch (bwa-mem2 → bcftools mpileup/call →
normalization → hard filtering), producing a panel methodologically
comparable to — but not a byte-for-byte reproduction of — the original GATK-
based calls. The reconstruction retained **93.0%** of biallelic SNPs after
filtering, closely matching the source study's own reported **93.9%**
retention, which supports the comparability claim.

`placement_reconstructed/` runs the full placement (ADMIXTURE, PCA, BIONJ
tree) against this reconstructed panel merged with the three isolates. **This
is the branch used for Figure 4 and Figure S3 in the manuscript.**

**A note on the tree image's provenance:** `13_build_tree.R` computes the
real BIONJ topology and the nearest-neighbor distances reported in
`distances/`, but its own automated rendering (`ggtree`, circular/fan
cladogram layout) never reached a submission-quality result despite many
rounds of fixes — the same layout also failed outright on the Santos-VCF
branch (see below). The image actually used for Figure S3,
`bionj_tree/tree_plot_reconstructed_panel.png`, was produced by the author
manually restyling an intermediate render in an external tool, outside this
Quartz pipeline. The underlying data it depicts is exactly what the script
computed; only the final visual polish was done externally.

## Verification against the authoritative VCF

The source study's actual filtered VCF was obtained later in the project
(from Dr. Antonio Santos). Rather than discard the reconstruction work, it
was used as an independent verification: `placement_santos_vcf/` reruns
ADMIXTURE and PCA against the real published calls (after renaming
contigs/samples to match this pipeline's conventions — see
`14_map_santos_samples.py` and `15_rename_santos_vcf.sh`).

**Both branches agree:**

| Method | Reconstructed panel | Santos's authoritative VCF |
|---|---|---|
| Supervised ADMIXTURE (K=6) | 99.995% Canada-trees ancestry, all 3 isolates | 99.995% Canada-trees ancestry, all 3 isolates |
| PCA (unsupervised) | Nearest to Canada-trees centroid; PC1/PC2/PC3 = 21.80/19.40/8.79% | Nearest to Canada-trees centroid; PC1/PC2/PC3 = 21.69/19.38/8.70% |

This concordance is reported in the manuscript's Methods/Limitations text as
the basis for treating the reconstruction-based placement as robust.

### The Santos-VCF tree was attempted and not completed — no file is shipped

A BIONJ tree was also attempted against the Santos VCF branch
(`20_santos_build_tree.R`, fan/circular layout matching the reconstructed
tree's style), but it failed twice — the circular layout rendered distorted
both times, for reasons not fully root-caused despite two independent fix
attempts. A fallback rectangular-layout script was written
(`21_santos_build_tree_rect.R`) but was never executed. **No tree file for
the Santos-VCF branch exists or is included in this package.** The
underlying placement conclusion does not depend on this figure — ADMIXTURE
and PCA both independently confirm the same result — but if a tree figure
specifically for the authoritative-VCF branch is needed for the manuscript,
this work is unfinished and would need to be picked back up (see
`placement_santos_vcf/README.md`).

## Directory structure

```
lachancea_placement/
  README.md                    # this file
  environment.yml               # conda environment specs (yeast-id, popgen)
  S1_strains.tsv                 # published panel's Table S1 strain metadata
  reconstruction/                 # reference prep, alignment, joint-calling, filtering
  placement_reconstructed/        # ADMIXTURE + PCA + BIONJ tree vs. reconstructed panel
    admixture/
    pca/
    bionj_tree/                   # includes tree_plot_reconstructed_panel.png (Figure S3)
  placement_santos_vcf/           # ADMIXTURE + PCA vs. authoritative VCF (no tree)
    admixture/
    pca/
    README.md
  distances/
    pairwise_distances.tsv        # exact within-group + nearest-panel-neighbor distances
    METRIC.md                     # distance metric, site count, source documentation
```

## Known gaps in this package

1. **`reconstruction/05b_apply_hard_filters.sh` is a faithful reconstruction,
   not a byte-identical copy.** It was originally written directly on the
   HPC system via an interactive heredoc and never saved to the working
   scratchpad this package was built from. Its filter expression and
   reported retention numbers are exact (verified against the run's actual
   output), but treat the file itself as documentation-grade.
2. **PLINK's env attribution required correction mid-project** — see
   `environment.yml`'s notes section. `10_make_plink_and_popfile.sh` (used
   by the reconstructed-panel branch) hardcodes `conda activate yeast-id`,
   but PLINK actually lives in `popgen`; the real successful run patched
   this live with `sed` before executing. Running the script as-written will
   fail unless this is corrected.
