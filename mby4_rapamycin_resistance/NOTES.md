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

## [unfilled] Session start
- Allocation: r02049
- Working directory: /N/scratch/bochman/mby4_rapamycin/
- MBY4 FASTQ source: [PATH_TO_MBY4_FASTQ — fill in actual path once known]
- Plasmidsaurus delivery metadata reviewed: [ ] basecaller/model confirmed: ____________

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
