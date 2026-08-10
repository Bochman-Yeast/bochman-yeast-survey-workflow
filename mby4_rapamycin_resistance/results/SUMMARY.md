# MBY4 rapamycin resistance — summary

**TEMPLATE ONLY — no pipeline has been run.** Every field below is `[TBD]`. Do not fill in
placeholder or illustrative numbers; leave `[TBD]` until real Quartz output exists, then
replace this entire file (following the pattern of
`../../yh156_assembly_and_synteny/README.md`'s "Final assembly statistics" section, which
states real numbers because the pipeline that produced them actually ran).

## Assembly QC

- Raw read N50: [TBD]
- Raw read mean length: [TBD]
- Raw read mean quality (Q): [TBD]
- Total yield / estimated coverage (vs. 12.1 Mb): [TBD]
- Basecaller/model used (determines Flye mode, minimap2 preset, Medaka model): [TBD]
- Polished assembly: size [TBD], contig count [TBD], N50 [TBD]
- Deviation from ~12.1 Mb reference size: [TBD] — flag if meaningful

## Aneuploidy / CNV flags

- Per-chromosome depth ratios (from `../asm_vs_asm/depth_ratio_by_chrom.R`): [TBD]
- Any chromosome/arm flagged outside normal ratio range: [TBD]
- TOR1 locus-level copy-number check: [TBD]

## Variant filtering funnel

| Stage | SNVs/indels | SVs |
|---|---|---|
| Raw MBY4-vs-S288c | [TBD] | [TBD] |
| MBY4-specific (after W303 subtraction) | [TBD] | [TBD] |
| TOR-pathway subset | [TBD] | [TBD] |

Note the coordinate-space caveat documented in `intersect_mby4_specific.sh` before trusting
the middle row — confirm which subtraction method was actually used and state it here.

## TOR-pathway gene status

| Gene | Systematic name | MBY4-specific variant? | Details | Coverage at locus |
|---|---|---|---|---|
| FPR1 | YNL135C | [TBD] | [TBD] | [TBD] |
| TOR1 (FRB domain) | YJR066W | [TBD] | [TBD] | [TBD] |
| TOR2 | YKL203C | [TBD] | [TBD] | [TBD] |
| KOG1 | YHR186C | [TBD] | [TBD] | [TBD] |
| LST8 | YNL006W | [TBD] | [TBD] | [TBD] |
| TCO89 | YPL180W | [TBD] | [TBD] | [TBD] |
| PDR-family efflux transporters | (multiple loci) | [TBD] | [TBD] | [TBD] |

Coordinates as used above come from `tor_pathway_genes.tsv` — **re-verify against SGD
before trusting this table**, per that file's own header.

## Top 10 candidates genome-wide (by predicted functional severity)

[TBD — populate from SnpEff/VEP output, once the full MBY4-specific set is annotated]

## Caveats

- **ONT error-rate limitations**, even after Medaka polishing: homopolymer indels in
  particular. Any candidate variant falling in a homopolymer run ≥4 bp: [TBD — list here,
  flagged as needing Sanger confirmation]
- **Manual pileup review**: any single-locus "answer"-looking finding (e.g. an FPR1
  truncation) must be manually checked against the raw read pileup before being reported as
  final — see `../results/README.md`. Confirm this was done for: [TBD]
- **Coverage gaps**: [TBD — any locus with <20-30x flagged by `tor_pathway_lookup.sh` or
  elsewhere]
- **W303 reference provenance/quality**: see `../reference/PROVENANCE.md` — as of this
  scaffold, the W303 accession itself is still unresolved/unverified; state the final choice
  and its quality caveats here once resolved.
