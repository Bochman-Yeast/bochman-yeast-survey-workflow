#!/usr/bin/env Rscript
# Independent cross-check of the ADMIXTURE placement: PCA via SNPRelate on the
# same merged genotype set, colored by known Table S1 cluster, with our 3
# strains highlighted. Two different methods (model-based ancestry estimation
# vs. PCA) agreeing on where our strains fall is a much stronger claim than
# either one alone.
library(SNPRelate)

workdir <- "/N/scratch/bochman/lachancea_pop/placement"
setwd(workdir)

vcf.fn <- "merged_for_placement.vcf.gz"
gds.fn <- "combined.gds"

snpgdsVCF2GDS(vcf.fn, gds.fn, method = "biallelic.only")
genofile <- snpgdsOpen(gds.fn)

pca <- snpgdsPCA(genofile, num.thread = 4, autosome.only = FALSE)

sample.id <- pca$sample.id
our_strains <- c("YH26", "YH72", "YH140")

# Pull cluster labels the same way 10_make_plink_and_popfile.sh did, so this
# stays consistent with what ADMIXTURE was told, rather than re-deriving it
# differently and risking a mismatch between the two cross-checks.
manifest <- read.delim("../download_manifest.tsv", stringsAsFactors = FALSE)
run_to_cluster <- setNames(manifest$genocluster, manifest$run_accession)

cluster <- sapply(sample.id, function(id) {
  if (id %in% our_strains) return("OUR_STRAIN")
  cl <- run_to_cluster[[id]]
  if (is.null(cl) || is.na(cl) || cl == "") return("unknown")
  cl
})

pct <- pca$varprop * 100
result <- data.frame(
  sample.id = sample.id,
  cluster = cluster,
  PC1 = pca$eigenvect[, 1],
  PC2 = pca$eigenvect[, 2],
  PC3 = pca$eigenvect[, 3]
)

write.csv(result, "pca_result.csv", row.names = FALSE)

cat(sprintf("PC1 variance explained: %.2f%%\n", pct[1]))
cat(sprintf("PC2 variance explained: %.2f%%\n", pct[2]))
cat(sprintf("PC3 variance explained: %.2f%%\n", pct[3]))
cat("\n")

cat("=== Our 3 strains' PCA coordinates ===\n")
print(result[result$cluster == "OUR_STRAIN", ])

cat("\n=== Per-cluster PC1/PC2 centroids (for eyeballing which our strains are nearest) ===\n")
centroids <- aggregate(cbind(PC1, PC2, PC3) ~ cluster, data = result, FUN = mean)
print(centroids)

# Simple scatter plot, saved rather than displayed (no X11 on a compute node).
# Plain geom_text for labels - ggrepel isn't in the popgen env, not worth
# adding just for label jitter on 3 points.
library(ggplot2)
p <- ggplot(result, aes(x = PC1, y = PC2, color = cluster)) +
  geom_point(data = subset(result, cluster != "OUR_STRAIN"), alpha = 0.6, size = 2) +
  geom_point(data = subset(result, cluster == "OUR_STRAIN"), size = 4, shape = 17, color = "black") +
  geom_text(data = subset(result, cluster == "OUR_STRAIN"),
            aes(label = sample.id), color = "black", size = 3, vjust = -1) +
  theme_minimal() +
  labs(title = "PCA: our 3 strains vs. published six-cluster panel",
       x = sprintf("PC1 (%.1f%%)", pct[1]),
       y = sprintf("PC2 (%.1f%%)", pct[2]))

ggsave("pca_plot.pdf", p, width = 8, height = 6)
cat("\nWrote pca_result.csv and pca_plot.pdf\n")

snpgdsClose(genofile)
