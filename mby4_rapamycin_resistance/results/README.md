# results/ — intersection, TOR-pathway lookup, annotation, summary

Step order matches the original task:

1. `intersect_mby4_specific.sh` — from the reference-based calls (`../variants/`, `../sv/`),
   identify variants present in MBY4-vs-S288c but *not* in MBY4-vs-W303 (i.e., not just
   W303-vs-S288c background divergence). Run separately for SNVs/indels and SVs. Uses
   `bcftools isec`; exact logic documented in the script's own header comment.
2. `tor_pathway_genes.tsv` — coordinates for the targeted TOR-pathway lookup (step 6).
   **Not independently verified from a primary source in this session** — see the file's
   own header and `../README.md` open decision point 3.
3. `tor_pathway_lookup.sh` — pulls the MBY4-specific variant status for each gene in
   `tor_pathway_genes.tsv`, plus the depth-ratio check at `TOR1` from `../asm_vs_asm/`.
4. SnpEff annotation of the full MBY4-specific set (not just the TOR-pathway subset) —
   script not yet written; needs a yeast SnpEff database name confirmed on Quartz first
   (see `../environment.yml`).
5. `SUMMARY.md` — template only, to be filled in with real numbers once the pipeline runs.
   Do not fill in placeholder numbers speculatively; leave `[TBD]` until real output exists.

## Manual pileup review requirement

Per the original task: any single-locus finding that looks like "the answer" (e.g. an
`FPR1` truncation) needs manual review of the raw read pileup at that position (e.g.
`samtools tview` or IGV against `../mapping/MBY4_vs_S288c.sorted.bam`) before being reported
as final — ONT basecalling errors can create spurious frameshifts in homopolymer-rich
regions. Note this explicitly in `SUMMARY.md` for whichever candidate(s) end up flagged.
