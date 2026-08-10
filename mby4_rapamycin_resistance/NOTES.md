# NOTES.md — running log

**Fill this in live, during the actual Quartz run — not reconstructed afterward.** Every
command, every tool version (from its own `--version`/stdout banner, not from
`environment.yml`), and every decision point (basecaller model, reference accession choice,
coverage/QC judgment calls) goes here as it happens, in order. See
`../yh156_assembly_and_synteny/environment.yml` for the standard this repo holds itself to:
distinguish versions *confirmed* from a real command's output from versions merely assumed.

Template entry format:

```
## YYYY-MM-DD HH:MM — <short description>
Command:
    <exact command run>
Tool version:
    <tool --version output, pasted verbatim>
Output/result:
    <key numbers, or path to output file>
Decision (if applicable):
    <what was decided and why>
```

---

## 2026-08-09 — Session start
- Allocation: r02049
- Working directory: /N/scratch/bochman/mby4_rapamycin/
- MBY4 FASTQ source: Plasmidsaurus delivery, run/order ID N7W3VV, delivered as
  `N7W3VV_1_MBY4.fastq.gz` (~1.03 GB compressed), no separate report file included.
  Transferred from local Windows machine via scp to
  `/N/scratch/bochman/mby4_rapamycin/raw/MBY4.fastq.gz`.
- Plasmidsaurus delivery metadata reviewed: [x] basecaller/model confirmed directly from
  FASTQ read headers (`zcat MBY4.fastq.gz | head -1`):
  `basecall_model_version_id=dna_r10.4.1_e8.2_400bps_sup@v4.3.0`
  (R10.4.1 flow cell chemistry, Dorado "sup" super-accuracy basecaller, v4.3.0). Also present
  in the header: flow_cell_id=PBM49684, basecall_gpu=NVIDIA_A100_80GB_PCIe,
  protocol_group_id=260808LV, sample_id=Y1, barcode=barcode18.

### Decision: basecaller-dependent pipeline choices
High-accuracy (Q20+) read class, all four downstream choices set accordingly:
- Flye: `--nano-hq` (not `--nano-raw`)
- minimap2: `-ax lr:hq` (not `-ax map-ont`)
- Medaka model: `r1041_e82_400bps_sup_v430` — derived from web search matching the exact
  basecaller version, NOT yet independently confirmed against this Quartz install's actual
  `medaka tools list_models` output. **Verify before running `assembly/medaka_polish.sbatch`.**
- Clair3 model: same caveat — `variants/clair3_*.sbatch` now auto-discovers a matching model
  under `$CONDA_PREFIX` and fails loudly if none is found, rather than silently using a wrong
  default. **Verify the discovered path is correct before trusting output.**

### Reference genomes (resolved this session, see reference/PROVENANCE.md for full detail)
- S288c: GCF_000146045.2 (R64), downloaded with genome+GFF3, headers renamed to
  `chrI`-`chrXVI` + `chrmt`.
- W303: GCA_965282845.1 chosen over GCA_002163515.1 (confirmed via
  `datasets summary genome accession` — better contiguity: 16 contigs/N50 932,960 bp vs. 196
  contigs scaffolded into 20 gapped pieces/N50 122,157 bp; also Nanopore not PacBio, and 2025
  not 2017). Downloaded, headers renamed to `chrI`-`chrXVI` (16 sequences — no mitochondrial
  contig in this assembly, confirmed absent).

### TOR-pathway gene coordinates (resolved this session, see results/tor_pathway_genes.tsv)
All six genes' coordinates confirmed from the S288c GFF3 by locus_tag (FPR1, TOR1, TOR2,
KOG1, LST8, TCO89). TOR1's FRB domain (chrX:564738-565886) and the S1972 resistance hotspot
(chrX:565329-565331) additionally confirmed from UniProt P35169.

### Environment split (this session)
`environment.yml` split into two files: the original name (`mby4_rapamycin`) keeps
everything except Clair3, and a new `environment_clair3.yml` (env name
`mby4_rapamycin_clair3`) holds Clair3 alone, isolating its pinned pytorch/tensorflow stack
from the rest of the toolchain's solve. `variants/clair3_*.sbatch` updated to activate the
new env name. Not yet built/tested on Quartz — do that before running `variants/`.
Also note: this Quartz install's conda has a broken `libmamba` solver plugin
(`GLIBCXX_3.4.31 not found`) — `conda create`/`env create` need `--solver classic` (or
`conda config --set solver classic` set globally) to work around it. Cosmetic error only;
doesn't block the classic solver from completing.

## [unfilled] Step 1 — QC (raw/)
- NanoPlot version:
- Command:
- N50:
- Mean length:
- Mean quality (Q):
- Total yield (bp):
- Estimated coverage (yield / 12.1 Mb):
- Concerns flagged:

**CHECK-IN POINT: report step 1 results to user and get confirmation before starting step 2
(de novo assembly). Do not proceed past this point without that confirmation.**

## [unfilled] Step 2 — assembly (assembly/)
...

## [unfilled] Step 3 — reference-based variant calling (mapping/, variants/, sv/)
...

## [unfilled] Step 4 — assembly-vs-assembly / aneuploidy screen (asm_vs_asm/)
...

## [unfilled] Step 5 — variant intersection (results/)
...

## [unfilled] Step 6 — TOR-pathway targeted lookup (results/)
...

## [unfilled] Step 7 — full-candidate annotation (results/)
...

## [unfilled] Step 8 — SUMMARY.md written
...
