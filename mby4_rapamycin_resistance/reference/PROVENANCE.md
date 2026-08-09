# Reference genome provenance

## S288c (R64)

**Accession:** GCF_000146045.2 — as specified in the original task. This is the standard,
well-established community reference (SGD/NCBI RefSeq).

## W303 — RESOLVED: GCA_965282845.1

Confirmed via `datasets summary genome accession <ACC>` run directly on Quartz
(2026-08-09) against both candidates identified in earlier literature/web search. Full
comparison:

| | Candidate A — GCA_002163515.1 (ASM216351v1) | **Candidate B — GCA_965282845.1 (chosen)** |
|---|---|---|
| Sequencing tech | PacBio | Nanopore |
| Assembly method | HGAP v.3 | CANU |
| NCBI `assembly_level` | "Chromosome" | "Contig" |
| Contig count | 196 (scaffolded into 20 pieces) | **16** |
| Contig N50 | 122,157 bp | **932,960 bp** |
| Total length | 12,338,538 bp | 12,233,549 bp |
| Mitochondrion | explicit 94,871 bp organelle contig | not reported in metadata — see caveat below |
| Submitter / date | Princeton University, released 2017-06-06 | Sorbonne University (via ENA), released 2025-06-02 |
| BioProject | PRJNA324291 ("W303 Genome sequencing and assembly") | PRJEB89249 ("Natural diversity of telomere length distributions across 100 *S. cerevisiae* strains") |
| Strain/biosample | W303 (BioSample SAMN05199423) | **W303-G49** (BioSample SAMEA118252021, collected 2024-12) |
| Genome coverage | 47x | 50x |

**Decision: GCA_965282845.1.** NCBI's `assembly_level` field ("Chromosome" vs "Contig") is
misleading here — it reflects whether sequences were assigned chromosome names, not
underlying contiguity. Candidate A is labeled "Chromosome" only because its 196 raw contigs
were scaffolded into 20 gapped pieces; candidate B's 16 *un-scaffolded* contigs — matching
the yeast nuclear chromosome count almost 1:1 — represent genuinely more complete, gap-free
sequence, with a contig N50 7.6x higher than candidate A's. It's also long-read Nanopore
(same platform as the MBY4 reads, unlike PacBio candidate A) and far more recent (2025 vs.
2017), matching the original task's explicit preference for "a recent PacBio/ONT W303
assembly" over an older, more fragmented one.

### Caveats to carry into downstream steps

1. **No chromosome-level naming/karyotype assignment.** The 16 contigs in GCA_965282845.1
   are not labeled `chrI`...`chrXVI` — confirm actual FASTA header names with
   `grep '>' reference/W303.fna` once downloaded. For `asm_vs_asm/depth_ratio_by_chrom.R`
   and any per-chromosome aneuploidy screen against this reference specifically (as opposed
   to against S288c, which does have standard chromosome names), contigs will need to be
   assigned to a chromosome identity first — e.g. by best-hit alignment to S288c, the same
   approach used in `../../yh156_assembly_and_synteny/synteny/build_and_run_syri_sv.sbatch`'s
   pseudo-chromosome-building step. Do this before trusting any "chromosome X is amplified"
   call made directly against the W303 reference's own contig coordinates.
2. **Mitochondrial genome not confirmed present.** Candidate A explicitly reports a 94,871 bp
   mitochondrial organelle contig; candidate B's metadata does not. Check the downloaded
   FASTA for a contig of roughly that size before assuming MBY4 mitochondrial reads will map
   at all against this W303 reference — if absent, that's a minor completeness gap (not
   expected to affect the nuclear TOR-pathway targeted search) but should be noted in
   `results/SUMMARY.md`'s caveats section.
3. **Strain sub-lineage.** This is specifically "W303-G49," one isolate from a 100-strain
   telomere-length survey, not necessarily an identical stock to whatever W303 background
   MBY4 may itself derive from. This is an unavoidable limitation of using any single
   reference strain as a stand-in for "W303" generally — flag it as a caveat in
   `results/SUMMARY.md` rather than treating W303-background variant calls as strain-exact.

### Download
```bash
datasets download genome accession GCA_965282845.1 --include genome
```
Extract and stage as `reference/W303.fna`, matching the path used throughout the sbatch
templates in `../mapping/`, `../variants/`, `../sv/`, and `../asm_vs_asm/`.
