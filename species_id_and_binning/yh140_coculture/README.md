# YH140 co-culture resolution

Isolate YH140 returned discordant ITS and LSU barcode identities
(*Lachancea thermotolerans* vs. *Torulaspora delbrueckii*) and an assembly
(19.9 Mb) roughly twice the expected size for a single yeast genome. This
directory documents the investigation that resolved it as a genuine
two-species co-culture, not contamination cross-talk or a misassembly
artifact.

## Binning method

**Not** a metagenomic binning tool (no MetaBAT/CONCOCT/etc. was used) and
**not** a coverage/GC-based rule. Assignment was made by competitive
whole-genome alignment:

1. Each assembly contig was aligned independently against two candidate
   reference genomes (*L. thermotolerans*, *T. delbrueckii*) with
   **minimap2 v2.31**, `-x asm10` preset.
2. For each contig, total aligned bases (summed across all alignment
   blocks, PAF column 10 — "number of matching bases") were compared
   between the two references.
3. The contig was assigned to whichever reference had more aligned bases,
   **provided at least 10% of the contig's own length was aligned to it**;
   contigs below that threshold for both references were left
   "unassigned."

Implementation: `pipeline/scripts/bin_contigs_by_reference.py`, driven by
`pipeline/scripts/investigate_mixed_sample.sh`.

## Corroborating, independent evidence

Two further checks, neither of which used the alignment-based criterion
above, both confirmed the same partition:

- **Read-level support** (`mixed_investigation/read_species_fraction.tsv`):
  filtered reads mapped independently to each reference (minimap2
  `-ax map-ont`, primary alignments only) — 78.9% of reads support
  *L. thermotolerans*, 41.2% support *T. delbrueckii* (not mutually
  exclusive; some reads map to both via conserved sequence). Both
  fractions are substantial, which rules out index/barcode cross-talk on
  the sequencing run (that would typically leave a small minority
  fraction for the "wrong" organism, not two comparable fractions).
- **Per-bin BUSCO completeness**
  (`mixed_investigation/busco_Lachancea_thermotolerans_short_summary.txt`,
  `mixed_investigation/busco_Torulaspora_delbrueckii_short_summary.txt`):
  each bin independently reaches >99.7% completeness with <0.2%
  duplication when assessed on its own — the signature of two clean,
  near-complete single-species genomes, not one confused/chimeric
  assembly.
- **Coverage and GC** (`yh140_contigs.tsv`, added later as figure-support
  data, combining Flye's own per-contig depth from `assembly_info.txt`
  with GC fraction computed directly from the assembly FASTA): the two
  bins' major contigs separate cleanly on coverage (~40–45x vs. ~10–12x)
  and, more modestly, on GC (~0.47 vs. ~0.42 length-weighted mean). This
  is genuinely independent corroboration, not circular restatement of the
  alignment-based assignment — coverage and GC were never part of the
  original binning criterion.

## Files

| File | Contents |
|---|---|
| `mixed_investigation/contig_bins.tsv` | Per-contig length, aligned bases/fraction to each reference, and final bin assignment |
| `mixed_investigation/read_species_fraction.tsv` | Fraction of filtered reads mapping to each reference |
| `mixed_investigation/busco_*_short_summary.txt` | Per-bin BUSCO completeness (native BUSCO short_summary format) |
| `yh140_contigs.tsv` | Per-contig table combining length, Flye-reported mean depth, computed GC fraction, and bin assignment — source data for the coverage/GC figure |

## Result

53.3% of the assembly (10,626,645 bp, 15 contigs) → *L. thermotolerans*;
46.2% (9,208,228 bp, 13 contigs) → *T. delbrueckii*; 0.4% (84,666 bp, 3
contigs) unassigned. The three unassigned contigs show a coverage/GC
signature (very high depth, very low GC) consistent with mitochondrial DNA
rather than ambiguous nuclear sequence.
