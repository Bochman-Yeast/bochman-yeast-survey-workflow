# asm_vs_asm/ — assembly-vs-assembly alignment (CNV/aneuploidy + SV cross-check)

Aligns the polished MBY4 assembly (`../assembly/medaka_polish/consensus.fasta`) against
each reference, two independent methods per the original task:

1. `minimap2_asm5.sbatch` — `minimap2 -x asm5`, producing PAF for dot plots (via `pafr` in
   R) and for a per-chromosome depth/coverage-ratio script.
2. `dnadiff.sbatch` — MUMmer4's `dnadiff`, as a second, independent alignment method with
   its own summary report.

## Aneuploidy / CNV screen

This is the step that catches whole-chromosome or arm-level copy-number changes, which
won't show up as SNPs and are a known route to drug resistance — explicitly called out in
the original task. `depth_ratio_by_chrom.R` (template, not yet written with real chromosome
names) computes per-reference-chromosome mean depth from the mapped-reads BAMs in
`../mapping/`, normalized to genome-wide mean depth, and flags any chromosome whose ratio
deviates meaningfully from 1.0 (e.g. ~1.5x for a trisomic chromosome, ~0.5x for a lost
copy in a context where ploidy allows it).

**Explicitly re-check the `TOR1` locus depth here** (original task step 6) — a local
copy-number gain at `TOR1` (not necessarily whole-chromosome) would show as an elevated
depth ratio over just that gene's coordinates relative to the rest of chromosome X, and is
a distinct hypothesis from whole-chromosome aneuploidy.
