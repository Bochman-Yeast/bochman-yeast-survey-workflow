#!/usr/bin/env Rscript
# Same PCA cross-check as 12_pca_crosscheck.R, against the Santos-VCF-based
# merge in santos_placement/.
library(SNPRelate)

workdir <- "/N/scratch/bochman/lachancea_pop/santos_placement"
setwd(workdir)

vcf.fn <- "merged_for_placement.vcf.gz"
gds.fn <- "combined.gds"

snpgdsVCF2GDS(vcf.fn, gds.fn, method = "biallelic.only")
genofile <- snpgdsOpen(gds.fn)

pca <- snpgdsPCA(genofile, num.thread = 4, autosome.only = FALSE)

sample.id <- pca$sample.id
our_strains <- c("YH26", "YH72", "YH140")

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

cat("\n=== Per-cluster PC1/PC2 centroids ===\n")
centroids <- aggregate(cbind(PC1, PC2, PC3) ~ cluster, data = result, FUN = mean)
print(centroids)

snpgdsClose(genofile)
cat("\nWrote pca_result.csv\n")
