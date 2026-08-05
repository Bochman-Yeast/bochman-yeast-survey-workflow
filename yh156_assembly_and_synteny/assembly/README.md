# Assembly correction

Final draft: Canu-only lineage (Flye and hifiasm were compared during assembler
selection but not used in the final draft; not included in this package).

Pipeline, in order:
1. Canu assembly (parameters/version: see `../environment.yml`)
2. Chimera correction — `trim_chimeras.sh`. Two contigs (fusing two chromosome-end
   regions each) were identified via cross-assembler comparison against an independent
   hifiasm assembly (breakpoints matched at identical coordinates) and split at verified
   junctions.
3. Consensus polishing — `medaka_polish.sbatch` (model r1041_e82_400bps_sup_v5.2.0,
   matched to this read data's Q20/R10.4.1-sup basecalling).
4. `YH156_canu.seqStore.sh` — Canu-internal bookkeeping script, retained for provenance.

Final file: `consensus.fasta` — 213 contigs, 17,071,085 bp, N50 147,818 bp. Included in
this package (md5 verified identical to the source file at
`results/YH156_v3_canu/medaka_polish/consensus.fasta` on Quartz). Used downstream in
`../busco/` (completeness benchmarking) and `../synteny/` (structural comparison).

**Excluded:** an earlier BUSCO run against the *unpolished*, pre-medaka draft
(56.0% complete) is superseded by the polished draft's 55.4% (see `../busco/`) and is not
included in this package.
