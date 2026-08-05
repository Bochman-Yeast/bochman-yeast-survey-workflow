#!/usr/bin/env Rscript
# BIONJ tree, circular cladogram layout (branch lengths ignored for spacing -
# topology/clustering is what matters here, not exact genetic distance, and
# equal-depth spacing keeps 148 tips legibly spread instead of collapsed near
# the root) with colored clade-background wedges, branch coloring by group,
# rotated rim labels, and radial leader-line callouts for our 3 strains -
# styled after a reference figure the user provided.
library(SNPRelate)
library(ape)
library(ggtree)
library(ggplot2)

ts <- function(msg) cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), msg))

workdir <- "/N/scratch/bochman/lachancea_pop/placement"
setwd(workdir)

genofile <- snpgdsOpen("combined.gds")
diss <- snpgdsDiss(genofile, num.thread = 4, autosome.only = FALSE)
distmat <- as.matrix(diss$diss)
rownames(distmat) <- diss$sample.id
colnames(distmat) <- diss$sample.id
tree <- bionj(as.dist(distmat))
ts("BIONJ tree built")

options(ignore.negative.edge = TRUE)
tree$edge.length[tree$edge.length < 0] <- 0
snpgdsClose(genofile)

our_strains <- c("YH26", "YH72", "YH140")
manifest <- read.delim("../download_manifest.tsv", stringsAsFactors = FALSE)
run_to_cluster <- setNames(manifest$genocluster, manifest$run_accession)

tip_ids <- tree$tip.label
cluster <- sapply(tip_ids, function(id) {
  if (id %in% our_strains) return("Our strains")
  cl <- run_to_cluster[[id]]
  if (is.null(cl) || is.na(cl) || cl == "") return("Unknown")
  cl
})
meta <- data.frame(label = tip_ids, cluster = cluster, stringsAsFactors = FALSE)
ts("metadata built")

cluster_levels <- c("Asia", "Americas", "Canada-trees", "Europe/Domestic-1",
                     "Europe/Domestic-2", "Europe-Mix", "Unknown", "Our strains")
meta$cluster <- factor(meta$cluster, levels = cluster_levels)

cluster_colors <- c(
  "Asia"               = "#2a78d6",
  "Americas"           = "#008300",
  "Canada-trees"       = "#e87ba4",
  "Europe/Domestic-1"  = "#eda100",
  "Europe/Domestic-2"  = "#1baf7a",
  "Europe-Mix"         = "#eb6834",
  "Unknown"            = "#4a3aa7",
  "Our strains"        = "#000000",
  "0"                  = "grey75"
)
cluster_shapes <- c(
  "Asia" = 16, "Americas" = 17, "Canada-trees" = 15,
  "Europe/Domestic-1" = 18, "Europe/Domestic-2" = 3,
  "Europe-Mix" = 8, "Unknown" = 4, "Our strains" = 18, "0" = NA
)

# Which clusters are actually monophyletic in THIS tree (unlike the reference
# image, ours may not cleanly separate into wedges - check rather than assume)
wedge_groups <- setdiff(cluster_levels, c("Unknown", "Our strains"))
mrca_nodes <- list()
for (g in wedge_groups) {
  tips_in_g <- meta$label[meta$cluster == g & !is.na(meta$cluster)]
  if (length(tips_in_g) < 2) next
  if (ape::is.monophyletic(tree, tips_in_g)) {
    mrca_nodes[[g]] <- ape::getMRCA(tree, tips_in_g)
    cat(sprintf("%s: monophyletic, MRCA node %d\n", g, mrca_nodes[[g]]))
  } else {
    cat(sprintf("%s: NOT monophyletic in this tree - skipping wedge highlight\n", g))
  }
}
ts("monophyly checked")

group_list <- split(meta$label, meta$cluster)
group_list <- group_list[sapply(group_list, length) > 0]
tree_grp <- groupOTU(tree, group_list)

# branch.length = "none" -> circular cladogram: all tips land on the same
# outer ring regardless of true genetic distance, so the tree actually fills
# the circle and tip spacing/clade shading render legibly. Real distances are
# still reported below in the nearest-neighbor summary.
p <- ggtree(tree_grp, layout = "fan", open.angle = 15, size = 0.4,
            branch.length = "none", aes(color = group)) %<+% meta
ts("ggtree object built")

tree_data <- p$data
max_x <- max(tree_data$x, na.rm = TRUE)
# max_x (largest x-COORDINATE) is only the tree's radius for tips that happen
# to sit near the 3 o'clock position - most tips (e.g. ones near the top or
# bottom of the fan) have small x despite being just as far from center. Use
# true radius for anything that needs to reach "the rim" regardless of angle.
max_r <- max(sqrt(tree_data$x^2 + tree_data$y^2), na.rm = TRUE)

for (g in names(mrca_nodes)) {
  p <- p + geom_hilight(node = mrca_nodes[[g]], fill = cluster_colors[[g]],
                         alpha = 0.15, extend = 0.03 * max_x, align = "right")
}
ts("wedges added")

p <- p +
  geom_tippoint(aes(color = group, shape = group), size = 2, na.rm = TRUE) +
  scale_color_manual(values = cluster_colors, na.value = "grey75", drop = FALSE) +
  scale_shape_manual(values = cluster_shapes, na.value = 1, drop = FALSE)

# Radial leader-line callouts for our 3 strains: each label projects straight
# outward along its OWN tip's true angle (no cross-label spreading - that was
# what previously sent a label swinging across the fan's angle discontinuity
# and through unrelated wedges). All tips sit at ~max_r (true radius, not
# max_x) in this cladogram, so a fixed callout radius works for all three.
our_data <- tree_data[!is.na(tree_data$cluster) & tree_data$cluster == "Our strains", ]
our_data$ang_rad_orig <- atan2(our_data$y, our_data$x)
callout_r <- max_r * 1.15
our_data$label_x <- callout_r * cos(our_data$ang_rad_orig)
our_data$label_y <- callout_r * sin(our_data$ang_rad_orig)

cat("=== Our strains' tip and callout label positions ===\n")
print(our_data[, c("label", "x", "y", "ang_rad_orig", "label_x", "label_y")])

p <- p +
  geom_point(data = our_data, aes(x = x, y = y), color = "black", size = 3, shape = 18, inherit.aes = FALSE) +
  geom_segment(data = our_data, aes(x = x, y = y, xend = label_x, yend = label_y),
               color = "black", linewidth = 0.3, inherit.aes = FALSE) +
  geom_label(data = our_data, aes(x = label_x, y = label_y, label = label),
             color = "black", fontface = "bold", size = 3.2, label.size = 0.3,
             inherit.aes = FALSE)
ts("callouts added")

# No per-cluster rim text - the color/shape legend already identifies every
# group unambiguously, and rotated rim labels kept overlapping/misreading
# regardless of angle or justification tweaks. Just give the callouts room.
# ggtree's fan layout sets explicit x/y scale limits sized to the tree itself
# - expand_limits() only widens an auto-computed range, it can't override an
# already-explicit limits=, so the callouts were getting silently clipped.
# Replace the scales outright with wider limits instead.
outer_extent <- max_r * 1.35
p <- p +
  scale_x_continuous(limits = c(-outer_extent, outer_extent)) +
  scale_y_continuous(limits = c(-outer_extent, outer_extent)) +
  theme(legend.position = "inside", legend.position.inside = c(0.02, 0.98),
        legend.justification = c(0, 1),
        legend.title = element_blank(), legend.background = element_blank(),
        plot.margin = margin(20, 20, 20, 20)) +
  ggtitle("L. thermotolerans: our 3 strains vs. 145-strain published panel (BIONJ, cladogram topology)")
ts("layout finalized")

ggsave("tree_plot.pdf", p, width = 14, height = 14, limitsize = FALSE)
ts("pdf saved")

cat("Tree written: tree_plot.pdf\n\n")
cat("=== Our strains' 5 nearest neighbors by genome-wide distance ===\n")
for (s in our_strains) {
  d <- distmat[s, ]
  d <- d[names(d) != s]
  nearest <- sort(d)[1:5]
  cat(sprintf("\n%s:\n", s))
  for (nm in names(nearest)) {
    cl <- meta$cluster[meta$label == nm]
    cat(sprintf("  %-15s (%-20s) dist=%.5f\n", nm, as.character(cl), nearest[nm]))
  }
}
