# YH156 species re-identification — verification only

**This directory covers verification, not reassembly.** YH156's
default-pipeline assembly was severely fragmented (426 kb, 54 contigs, 0%
BUSCO) — an unrelated failure (a Flye coverage-filter artifact driven by an
extreme-coverage rDNA repeat array, not a lineage issue). A separate
investigation, in a different working context, produced a reassembled
draft genome and an initial candidate identification of *Schizosaccharomyces
japonicus*. **That reassembly is packaged separately** (referred to during
this project as the "YH156_v3_canu" package) — it is not duplicated here.

What *is* here: the independent verification, performed in this session,
that tested the *S. japonicus* candidate call and did not support it, then
identified and confirmed the actual species.

## What was tested and found

| Reference tested | Accession | ANI % | Query align. fraction | Result |
|---|---|---|---|---|
| *S. japonicus* (strain yFS275) | GCF_000149845.2 | 87.94 | 56.02% | Refuted — below the 95% species boundary |
| *S. versatilis* (nom. inval., type strain CBS 103) | GCA_032882995.1 | **99.14** | **71.95%** | Confirmed — decisively above the boundary |

(`ani_comparison_summary.tsv` — compiled from the two ANI runs; note the
99.14% figure exists only as this compiled record, since the original
`skani` invocation that produced it was not run with `-o` to save a source
file. If this number needs a directly-citable raw output file, re-run
`skani dist -q <draft assembly> -r <S. versatilis genome.fna> -s 70 --slow
-o <file>` — same parameters as the rest of this project's ANI steps.)

A panel test against all four currently recognized *Schizosaccharomyces*
species (`schizo_panel_ani.tsv`) found *S. japonicus* to be the only one
even clearing skani's screening threshold — confirming genus-level
placement was correct while species-level placement was not.

`contamination_check/blast_results.tsv` — the evidence that motivated
testing *S. versatilis* in the first place: a sample of draft-assembly
contigs that aligned poorly to *S. japonicus* were BLASTed against `nt` and
returned consistently higher identity (96–99.8%, 100% query coverage) to
*S. versatilis* CBS 103 across all three of its chromosomes.

`busco_ascomycota/` — BUSCO completeness for the draft assembly, run
against the taxonomically correct `ascomycota_odb10` lineage (75.8%
complete) rather than the mismatched `saccharomycetes_odb10` default (see
`../README.md` "Known limitations" and `../busco/manual_lineage_correction.sh`).

`manual_note.txt` — the full written rationale for the corrected call, in
the format the main pipeline's `05_consensus_report.py` reads to override
an isolate's reported call with an externally-verified finding.

## Bottom line

**YH156 = *Schizosaccharomyces versatilis* (nom. inval.)**, not
*S. japonicus*. "nom. inval." (*nomen invalidum*) indicates this species
name has not yet been formally, validly published under the applicable
nomenclatural code — this wild isolate matching the 2023-deposited type
strain at species level is itself notable corroborating evidence for the
taxon, independent of this project's manuscript.
