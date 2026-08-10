# variants/ — small variant (SNV/indel) calling with Clair3

ONT-specific caller, per the original task's explicit instruction not to use a short-read
caller (e.g. GATK HaplotypeCaller) on raw ONT data. Basecaller confirmed as
`dna_r10.4.1_e8.2_400bps_sup@v4.3.0` (see `../NOTES.md`); expected matching Clair3 model is
`r1041_e82_400bps_sup_v430`, **not yet independently confirmed** against this Quartz
install's actual model list — both sbatch scripts below auto-discover the model path at
runtime and fail loudly if it's missing rather than silently defaulting.

Runs in its own conda env (`mby4_rapamycin_clair3`, see `../environment_clair3.yml`),
separate from the main `mby4_rapamycin` env used everywhere else in this package — Clair3's
pinned pytorch/tensorflow stack is a common source of solver conflicts if bundled together.

- `clair3_s288c.sbatch` → `MBY4_vs_S288c.clair3.vcf.gz`
- `clair3_w303.sbatch` → `MBY4_vs_W303.clair3.vcf.gz`

Check per-locus depth before trusting any call — flag anything below ~20-30x explicitly
rather than reporting it as a confident call (per the original task's rigor requirements),
especially at the TOR-pathway loci checked in `../results/`.
