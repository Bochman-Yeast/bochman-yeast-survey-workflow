# YH156 assembly correction and synteny comparison

Package B (Paper 2, Areas 3-assembly and 4): the reassembly/polishing half of the YH156
species-correction narrative, plus the whole-genome structural comparison against the
*Schizosaccharomyces versatilis* CBS 103 type strain. The ANI-verification half of the
species correction is packaged separately (`../species_id_and_binning/`).

## Narrative

YH156 was initially misdiagnosed as a failed sequencing run (426,170 bp, 54 contigs, 0%
BUSCO) due to a wrong BUSCO lineage default and an assembler coverage-filter artifact
(rDNA repeat array inflating the genome-wide mean coverage estimate). A corrected
assembly (Canu, chimera-corrected, medaka-polished; see `assembly/`) was built, and its
completeness was benchmarked (`busco/`) against both the originally-assumed reference
(*S. japonicus*) and the actually-correct reference, identified via whole-genome ANI
(87.94% vs. *S. japonicus*, below the 95% species boundary; 99.14% vs. *S. versatilis*
CBS 103, GCA_032882995.1 — see `reference/PROVENANCE.md`). The corrected draft was then
compared to the CBS 103 reference genome-wide (`synteny/`), identifying three
high-confidence structural rearrangements and resolving a complex repeat signal on
chromosome 2 as a dispersed Tf1/Tf2-type LTR retrotransposon family.

## Final assembly statistics
213 contigs, 17,071,085 bp, N50 147,818 bp (`assembly/` — see subfolder README for the
pipeline that produced this file).

## Contents
- `assembly/` — chimera-correction and polishing scripts
- `busco/` — the three-way BUSCO comparison behind Figure S1
- `synteny/` — SyRI/plotsr structural comparison behind Figure 3, Figure S2, Table S3
- `reference/` — the corrected *S. versatilis* CBS 103 reference genome and its provenance
- `environment.yml` — tool versions used (see file for per-tool version-confirmation notes)
