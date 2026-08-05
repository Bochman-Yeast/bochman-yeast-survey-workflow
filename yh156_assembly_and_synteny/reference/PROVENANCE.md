# Reference genome provenance

**Accession:** GCA_032882995.1 — *Schizosaccharomyces versatilis* (nom. inval.), strain
CBS 103. Complete genome (ONT + PacBio + Illumina), 3 chromosomes, 15,482,186 bp total,
N50 4,455,726 bp. Strain isolated 1945 from home-canned grape juice (USA); genome
published 2023-08-31 (submitter: National Institute of Biological Sciences, Beijing).

## Why this reference, and not S. japonicus

YH156 was originally identified via BLAST as *Schizosaccharomyces japonicus* and all
initial assembly validation used that species' reference genome (GCF_000149845.2).
Whole-genome ANI subsequently showed this was wrong:

| Reference | ANI | Align. fraction (query) | Verdict |
|---|---|---|---|
| *S. japonicus* GCF_000149845.2 | 87.94% | 56.0% | below 95% species boundary |
| *S. versatilis* CBS 103 (this reference) | 99.14% | 72.0% | decisively above boundary |

*S. japonicus* was the "obvious" species to check first (well-known, heavily
characterized) but *S. versatilis* — an obscure, only-recently-deposited (2023),
nomenclaturally-unvalidated ("nom. inval.") type strain — is the actual correct
identification. This also resolved an earlier puzzle: draft assemblies looked ~1.5-1.8x
"inflated" relative to the *S. japonicus* reference (11.2 Mb) purely because that
reference is genuinely ~4 Mb smaller than the true species (15.48 Mb).

**Verification performed before accepting this reference:** the accession was
independently confirmed via `datasets summary genome accession GCA_032882995.1`
(matching organism name, strain, assembly stats) before use, and the ANI comparison was
independently re-run on the project's own canonical assembly file rather than trusted
from a single source.
