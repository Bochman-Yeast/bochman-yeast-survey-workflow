# variants/ — small variant (SNV/indel) calling with Clair3

ONT-specific caller, per the original task's explicit instruction not to use a short-read
caller (e.g. GATK HaplotypeCaller) on raw ONT data. Requires a Clair3 model matching the
basecaller (rerio/Clair3 model bundle) — **not yet selected**, must match the same
basecaller-model decision as `../assembly/` and `../mapping/` (see `../raw/README.md`).

- `clair3_s288c.sbatch` → `MBY4_vs_S288c.clair3.vcf.gz`
- `clair3_w303.sbatch` → `MBY4_vs_W303.clair3.vcf.gz` (blocked on W303 accession resolution,
  see `../reference/PROVENANCE.md`)

Check per-locus depth before trusting any call — flag anything below ~20-30x explicitly
rather than reporting it as a confident call (per the original task's rigor requirements),
especially at the TOR-pathway loci checked in `../results/`.
