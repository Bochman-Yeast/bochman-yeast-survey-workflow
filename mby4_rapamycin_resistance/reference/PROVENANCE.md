# Reference genome provenance

**Neither reference below has been downloaded or independently verified in this session.**
This session's network egress proxy blocks `ncbi.nlm.nih.gov`, `pmc.ncbi.nlm.nih.gov`, and
`yeastgenome.org` directly, so every accession/detail below comes from web-search snippets
only, not a fetched primary page. Re-verify everything in this file on Quartz (e.g.
`datasets summary genome accession <ACC>`, or a direct SGD/NCBI page load) before using
either reference for real analysis, and update this file with the confirmed details —
following the pattern of `../../yh156_assembly_and_synteny/reference/PROVENANCE.md`, which
documents an accession that *was* independently confirmed before use.

## S288c (R64)

**Accession:** GCF_000146045.2 — as specified in the original task. This is the standard,
well-established community reference (SGD/NCBI RefSeq), so no additional vetting of the
accession itself is needed beyond the routine `datasets summary genome accession
GCF_000146045.2` sanity check before download.

## W303 — NOT YET RESOLVED, two unverified candidates

The original task requires a **complete, long-read (PacBio/ONT) W303 assembly**, explicitly
*not* an older short-read scaffold assembly, because step 4 (assembly-vs-assembly alignment
for CNV/aneuploidy) and the SV cross-check need contiguity to be reliable. Web search from
this session surfaced two candidates; both need verification on Quartz before either is used:

### Candidate A — GCA_002163515.1 (ASM216351v1)
- From Matheson, Rossouw & Bauer (or similar authorship — title captured as "Whole-Genome
  Sequence and Variant Analysis of W303, a Widely-Used Strain of *Saccharomyces cerevisiae*,"
  *G3: Genes|Genomes|Genetics* 7(7):2219, 2017; also cross-listed on the PacBio publications
  page).
- Search snippets describe PacBio sequencing, de novo assembly, polishing with HGAP and
  Quiver — i.e. genuinely long-read and reasonably contiguous, matching the task's
  requirement. Also reports ~9,500 W303-vs-S288c variant sites affecting ~700 genes, which
  this package's README cites as the rationale for comparing against W303 at all.
- **Not verified in this session:** actual contig count/N50/total size, whether this
  accession is "GenBank" (GCA) with a corresponding RefSeq (GCF) that might be preferred,
  and whether a newer reassembly of the same underlying data exists.

### Candidate B — GCA_965282845.1
- Surfaced by NCBI Datasets search as "Saccharomyces cerevisiae genome assembly W303" but
  this session could not open the NCBI Datasets page (network-blocked) to confirm sequencing
  technology, assembly level, submitter, or date. The accession-number pattern (GCA_9652...)
  is consistent with more recent (2023+) submissions, which would make it the better match
  for "recent" per the task instructions if it holds up — but this is speculation from the
  accession number alone, not a confirmed fact.
- **Not verified in this session:** essentially everything — sequencing technology
  (PacBio/ONT/Illumina — the task explicitly rules out an old short-read scaffold assembly,
  so this must be checked before use), assembly level, contig count/N50, submitter/BioProject.

### Resolution needed on Quartz, before `mapping/` or `asm_vs_asm/` run against W303
1. `datasets summary genome accession GCA_002163515.1` and `GCA_965282845.1` — compare
   assembly level, contig count, N50, sequencing technology (check the assembly report /
   BioProject description for the actual read type).
2. Also search NCBI directly (not blocked from Quartz) for any W303 assembly newer than both
   candidates — literature search from this session was not exhaustive given the network
   restriction, and the task specifically asked for a search of "recent PacBio/ONT W303
   assembly," which deserves a direct NCBI query rather than relying on this session's
   indirect web-search results.
3. Record the final choice and reasoning here, replacing this section, before proceeding —
   per the task's explicit instruction to report the selection before use.
