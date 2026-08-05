# Supporting Analyses: Heterozygosity, Private Variants, CNV/Aneuploidy

These go beyond the core population placement but are part of this session's population-genomics
work on the same five isolates.

## Citation status (verified directly against the manuscript, not assumed)

**Both analyses are cited in the manuscript body text** — this corrects an initial assumption
that they might be "included but uncited." Neither has a dedicated figure or table; both are
discussed as cited prose in the main text:

- **Heterozygosity/private-variant analysis**: manuscript has a dedicated methods subsection,
  *"Heterozygosity and private-variant analysis,"* describing exactly the method in
  `heterozygosity/heterozygosity.out` and `heterozygosity/private_snps.out`.
- **CNV/aneuploidy screening**: manuscript text, *"Chromosome-level relative copy number was
  assessed with..."*, discussing the rDNA-locus coverage finding and the chromosome XI
  subtelomeric-loss candidate in `cnv_aneuploidy/`.

(The manuscript's only two dedicated tables — Table 1, isolate provenance/species assignments,
and Table S1, reference genomes/panels — are neither of these; both analyses live in the main
text as prose, not as standalone tables.)

## Contents

- `heterozygosity/` — per-isolate heterozygosity rate (heterozygous SNP count ÷ reference genome
  length) compared against panel per-superclade means, plus the private/novel-SNP fraction
  analysis (positions absent from the panel's 1,916,611-site catalog).
- `cnv_aneuploidy/` — chromosome-level relative copy number (`samtools coverage`) and windowed
  (1 kb, `mosdepth`) depth, including the cross-referencing step that separates shared
  reference-mapping artifacts (114 regions recurring across ≥3 of 5 isolates — e.g., the rDNA
  locus on chromosome XII) from isolate-specific candidates (notably a ~21 kb subtelomeric
  depth loss unique to YH229 on chromosome XI).

Both are independent of, and unaffected by, the withdrawn *S. eubayanus* interspecies screen
(see top-level README).
