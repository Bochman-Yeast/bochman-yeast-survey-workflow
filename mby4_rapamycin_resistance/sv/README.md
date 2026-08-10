# sv/ — structural variant calling with Sniffles2

Separate from Clair3's small-variant calls (per the original task's step 3: 4 VCFs total,
one SNV set and one SV set per reference). Must be Sniffles2, not Sniffles1 — check
`sniffles --version` reports a 2.x version before trusting output format/flags.

- `sniffles_s288c.sbatch` → `MBY4_vs_S288c.sniffles.vcf`
- `sniffles_w303.sbatch` → `MBY4_vs_W303.sniffles.vcf` (blocked on W303 accession
  resolution, see `../reference/PROVENANCE.md`)

Cross-check SV calls here against the assembly-vs-assembly alignment in `../asm_vs_asm/` —
concordant calls from two independent methods (read-based SV calling vs. assembly
alignment) are much higher confidence than either alone, especially for anything near a
repeat or homopolymer region.
