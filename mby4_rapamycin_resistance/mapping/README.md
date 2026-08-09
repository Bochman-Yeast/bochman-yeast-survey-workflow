# mapping/ — MBY4 raw reads mapped to each reference

Two independent mappings, one per reference (needed for step 3's dual variant calling and
the step 5 intersection). Uses raw MBY4 reads (not the polished assembly — that's the
asm-vs-asm comparison in `../asm_vs_asm/`).

- `map_to_s288c.sbatch` — MBY4 reads vs S288c R64 (GCF_000146045.2)
- `map_to_w303.sbatch` — MBY4 reads vs W303 (accession TBD — see `../reference/PROVENANCE.md`)

minimap2 preset: `map-ont` for standard ONT reads, or `lr:hq` for newer high-accuracy
(Q20+/R10.4.1-sup) reads — matches the same basecaller-model decision as `../assembly/`
(see `../raw/README.md`). Both scripts currently default to `map-ont`; change both
consistently if the reads qualify as high-accuracy, and log the choice in `../NOTES.md`.
