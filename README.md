# Paper 2 Bioinformatic Workflow

Bioinformatic workflow supporting Paper 2: a wild-yeast bioprospecting survey spanning
three genera (*Saccharomyces*, *Schizosaccharomyces*, *Lachancea*). This repository covers
species identification of the isolate collection, resolution of a mixed-culture sample,
whole-genome structural comparison of a re-identified isolate, and population-level
phylogenomic placement of the *Saccharomyces* and *Lachancea* isolates within their
respective published reference panels.

This is the single repository referenced by Paper 2's Data Availability statement and is
intended to resolve to one Zenodo DOI.

## What's in each subdirectory

| Directory | Produces |
|---|---|
| `species_id_and_binning/` | Table 1 species calls; Figure S4 (YH140); YH156 ANI values in text |
| `yh156_assembly_and_synteny/` | Figure 3; Figure S1; Figure S2; Table S3 |
| `saccharomyces_placement/` | Figure 2; YH166 admixture and YH229 fine-clade values in text |
| `lachancea_placement/` | Figure 4; Figure S3; the pairwise-distance values in text |

## What this repository does NOT include: the YH166/YH229 introgression-withdrawal analysis

An initial apparent *S. cerevisiae* × *S. eubayanus* interspecies-hybrid signal for isolates
YH166 and YH229 (surfaced during the `saccharomyces_placement/` work below) was investigated
in depth and **withdrawn** — it was determined to be a competitive-mapping artifact, not
genuine interspecies ancestry. The withdrawal investigation itself (the matched-depth floor,
coordinate-recurrence, terminus-masking, read-composition, and assembly-representation
criteria used to reach that conclusion) is **not part of this deposit**. That analysis is
packaged and cited separately as the **FIDDL toolkit**:

- Repository: `[CALL-OUT: confirm FIDDL's actual repository URL before publishing this
  README — see the note in CITATION.cff; FIDDL's own pyproject.toml still has this as an
  unresolved placeholder, not a confirmed URL]`
- DOI: `[CALL-OUT: confirm FIDDL's actual minted DOI before publishing this README — see the
  note in CITATION.cff; FIDDL's own CITATION.cff still has this as an unresolved placeholder]`

`saccharomyces_placement/` documents this same cross-reference in its own README — the
placement, admixture, and fine-clade results there are SNP/panel-genotype-based, methodologically
independent of the withdrawn screen, and unaffected by its outcome.

## Environment setup

**Each subdirectory has its own environment — these are four genuinely different toolchains
(bwa-mem2/bcftools/PLINK/ADMIXTURE/R-ape for Lachancea; BUSCO/SyRI/plotsr/Canu/medaka for
YH156; skani/minimap2/BUSCO for species-ID; FastTree/panel tools for Saccharomyces) and are
not merged into one shared environment file.** See each subdirectory's own README and
`environment.yml` for tool-specific setup:

- `species_id_and_binning/README.md` + `environment.yml`
- `yh156_assembly_and_synteny/README.md` + `environment.yml`
- `saccharomyces_placement/README.md` + `environment.yml`
- `lachancea_placement/README.md` + `environment.yml`

**Known cross-package environment issues** (documented here rather than by editing the
individual packages, to leave each package's internals as originally validated):

- `species_id_and_binning/environment.yml` and `saccharomyces_placement/environment.yml`
  both declare `name: yeast-id`, but with substantially different dependency sets (the
  former is a curated ~20-package spec; the latter is a full ~480-line `conda env export`
  of the broader Quartz working environment). Creating both on the same machine with their
  declared names will collide — rename one (e.g. `conda env create -f environment.yml -n
  yeast-id-placement`) if you need both installed simultaneously.
- `lachancea_placement/environment.yml` is entirely commented out (documentation of the two
  conda environments used — `yeast-id` and `popgen` — rather than a runnable spec). Running
  `conda env create -f environment.yml` on it as-is will create an empty environment; consult
  the comments in that file and `lachancea_placement/README.md` for the actual dependencies.

## A note on `yh156_assembly_and_synteny/README.md`

That package's README refers to the species-ID verification work as packaged in
"`packaging_A_species_id_and_binning.md`" — a leftover reference from before this repository
was assembled. The actual location is this repository's `species_id_and_binning/` directory
(see the table above).

## Citation

- Manuscript: `[CALL-OUT: Paper 2's actual manuscript title, authors, journal, year, DOI once available]`
- This repository's own DOI: `10.5281/zenodo.21811551`

See `CITATION.cff` for the full machine-readable citation record, including the caveats
above on the FIDDL reference's currently-unresolved URL and DOI.
