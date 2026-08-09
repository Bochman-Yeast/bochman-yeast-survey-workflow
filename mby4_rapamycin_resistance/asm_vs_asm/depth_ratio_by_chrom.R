# depth_ratio_by_chrom.R — per-chromosome depth ratio screen for whole-chromosome / arm-level
# aneuploidy and locus-level copy-number gain (e.g. at TOR1).
#
# STATUS: untested template, not yet run. Needs `samtools depth` (or `samtools coverage`)
# output from ../mapping/*.sorted.bam as input — this script does not run samtools itself,
# to keep the depth-generation step (which should go in an sbatch job) separate from the
# plotting/summary step (which can run locally on Quartz's login node or an interactive R
# session, since it's cheap once the depth file exists).
#
# Suggested depth-generation command (run before this script, ideally inside an sbatch job
# given genome-wide per-base depth files can be large):
#   samtools depth -a MBY4_vs_S288c.sorted.bam > MBY4_vs_S288c.depth.txt
#
# S288c R64 chromosome names (standard, chrI-chrXVI + mitochondrial chrmt/chrM depending on
# the FASTA header convention in the downloaded reference — confirm actual header names with
# `grep '>' reference/S288c_R64.fna` before running, since minimap2/samtools depth output
# will use whatever names are in the reference FASTA, not necessarily these).

library(dplyr)
library(readr)
library(ggplot2)

depth_file <- "MBY4_vs_S288c.depth.txt"   # samtools depth -a output: chrom, pos, depth
tor1_locus <- list(chrom = "chrX", start = NA, end = NA)  # PLACEHOLDER — fill in TOR1
                                                            # coordinates from
                                                            # ../results/tor_pathway_genes.tsv
                                                            # once verified

depth <- read_tsv(depth_file, col_names = c("chrom", "pos", "depth"), show_col_types = FALSE)

genome_mean_depth <- mean(depth$depth)

per_chrom <- depth %>%
  group_by(chrom) %>%
  summarise(mean_depth = mean(depth), n_pos = n()) %>%
  mutate(ratio_to_genome_mean = mean_depth / genome_mean_depth)

print(per_chrom, n = Inf)

cat("\n--- chromosomes flagged (ratio outside [0.75, 1.3], adjust threshold as needed) ---\n")
per_chrom %>% filter(ratio_to_genome_mean < 0.75 | ratio_to_genome_mean > 1.3) %>% print(n = Inf)

if (!is.na(tor1_locus$start)) {
  tor1_depth <- depth %>%
    filter(chrom == tor1_locus$chrom, pos >= tor1_locus$start, pos <= tor1_locus$end)
  tor1_mean <- mean(tor1_depth$depth)
  chrom_mean <- per_chrom %>% filter(chrom == tor1_locus$chrom) %>% pull(mean_depth)
  cat(sprintf(
    "\nTOR1 locus mean depth: %.1f | chromosome mean: %.1f | ratio: %.2f\n",
    tor1_mean, chrom_mean, tor1_mean / chrom_mean
  ))
} else {
  cat("\nTOR1 coordinates not yet filled in — see ../results/tor_pathway_genes.tsv\n")
}

ggsave(
  "depth_ratio_by_chrom.png",
  ggplot(per_chrom, aes(x = chrom, y = ratio_to_genome_mean)) +
    geom_col() +
    geom_hline(yintercept = 1, linetype = "dashed") +
    theme_minimal() +
    labs(y = "mean depth / genome-wide mean depth", x = NULL,
         title = "MBY4 vs S288c per-chromosome depth ratio"),
  width = 8, height = 4
)
