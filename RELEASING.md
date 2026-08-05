# Releasing this repository (author does this manually — not automated by this build)

This repository is prepared but not published: no remote has been added, nothing has been
pushed, and no accounts have been created on the author's behalf. The steps below are for
the author to follow when ready to make the repository public and mint a citable DOI.

## 1. Fill in the placeholders

Search the repo for `[CALL-OUT` and replace every instance before making anything public:
- `README.md`: this repository's own name/description, manuscript citation, this
  repository's own DOI (bottom of the file), and the FIDDL repository URL/DOI cross-reference
- `CITATION.cff`: this repository's title, release date, DOI, repository URL, the manuscript's
  actual title, and the FIDDL reference's repository-code/doi fields

**Before filling in the FIDDL reference fields**, confirm FIDDL's own repository and DOI are
actually live — as of this repository's assembly, FIDDL's own `CITATION.cff` and
`pyproject.toml` still carry unresolved `[CALL-OUT]` placeholders for both its DOI and its
repository URL. Fix FIDDL's own citation file first (a separate, independent task from this
repository), then copy the resolved values here.

## 2. Create the GitHub repository

1. Create a new, empty repository on GitHub (do not initialize with a README/license/gitignore
   — this repo already has all three).
2. From this local repo:
   ```bash
   git remote add origin <your-repo-url>
   git branch -M main
   git push -u origin main
   ```

## 3. Connect Zenodo (for the DOI)

1. Log in to [zenodo.org](https://zenodo.org) with your GitHub account (or link GitHub under
   Account Settings -> Linked Accounts if already using a different Zenodo login).
2. Go to [zenodo.org/account/settings/github](https://zenodo.org/account/settings/github) and
   toggle the new repository "on" in the list of your GitHub repos. If it doesn't appear, click
   "Sync now."
3. This does *not* archive anything yet — Zenodo only archives on a **GitHub Release** (a git
   tag alone is not sufficient).

## 4. Cut a GitHub Release

1. On GitHub: Releases -> "Draft a new release."
2. Tag it (e.g. `v1.0.0`, matching `CITATION.cff`'s `version`).
3. Publish the release.
4. Zenodo automatically archives the tagged snapshot and mints a DOI within a few minutes —
   check [zenodo.org/account/settings/github](https://zenodo.org/account/settings/github) or
   your Zenodo uploads for the new record.

## 5. Back-fill the DOI

Once Zenodo has minted the DOI:
1. Update `CITATION.cff`'s `doi:` field.
2. Update `README.md`'s Citation section.
3. Commit and push these updates (a new commit on `main` is fine — it does not need its own tag
   unless you want the DOI-bearing commit to also be a tagged release).
4. Zenodo also generates a "concept DOI" that always resolves to the latest version, useful for
   citing "the software" generically rather than one specific release — consider using that one
   in the manuscript's Data Availability statement if you expect to cut further releases after
   publication.

## 6. Optional: badges

Once the DOI exists, Zenodo provides a Markdown badge snippet on the record's page —
straightforward to add near the top of `README.md` if wanted.

## A note specific to this repository (size) — ACTION REQUIRED at release time

This repository is roughly 252 MiB, dominated by `saccharomyces_placement/` (~150 MB, mostly
`placement/combined_alignment.fasta` and per-isolate VCFs) and `yh156_assembly_and_synteny/`
(~101 MB, mostly the reference genome, draft assembly, and SyRI/synteny intermediates).

**`saccharomyces_placement/placement/combined_alignment.fasta` is ~135.4 MB (141,965,313
bytes) — this exceeds GitHub's 100 MB hard per-file limit.** Resolution: this file is
**excluded from git** (see `.gitignore`) rather than pushed via Git LFS. It remains present
on disk locally and is **not deleted** — nothing currently regenerates it automatically (see
below), so removing the only copy would be destructive.

**At release time, this file must be uploaded directly to the Zenodo deposit as a
supplementary file**, alongside (not instead of) the GitHub-archived repository that Zenodo
creates automatically from the tagged release (Section 4 above). Zenodo deposits accept
additional files beyond what's in the archived GitHub snapshot — add it there manually before
finalizing the deposit, and reference it from `saccharomyces_placement/README.md` /
the top-level `README.md` once done (e.g. "combined_alignment.fasta is included in the Zenodo
deposit as a supplementary file, not in the GitHub-tracked repository").

**Regenerating this file instead of relying on the uploaded copy:** it is produced by
`saccharomyces_placement/placement/scripts/build_alignment.py`. Two caveats for a future user
attempting this:
1. The script hardcodes an absolute Quartz path (`PROJ =
   "/N/scratch/bochman/yeast_id/scerevisiae_popgen"`) rather than a relative path — it will
   need editing to point at wherever this repository actually lives before it can run.
2. It reads three inputs from `placement/`: `panel_sample_names.txt` and
   `newsamples_matrix.tsv` (both present in this repository) plus
   **`panel_genotypes_subset.tsv`, which is NOT included in this deposit** — it falls under
   the "large intermediate files... excluded" note in `saccharomyces_placement/README.md`
   (regenerable from the panel's own public Zenodo deposits, `10.5281/zenodo.12580561` /
   `10.5281/zenodo.12571280`, plus this repository's scripts). Without that file, the script
   cannot be run as-is — a future user needing to regenerate `combined_alignment.fasta` from
   scratch must first reconstruct `panel_genotypes_subset.tsv` from the cited panel deposits.

Estimated size of `panel_genotypes_subset.tsv` if regenerated: ~580–615 MB (3,034 panel
samples × 50,437 candidate sites, ~3–4 bytes per genotype field), roughly 4–5× larger than
`combined_alignment.fasta` itself — hence also excluded here.

For any *other* file that turns out to exceed 100 MB in the future (none currently do besides
this one; the next-largest tracked file is the ~22.7 MB `YH156_vs_sv.delta`), use
[Git LFS](https://git-lfs.github.com/) rather than repeating this exclude-and-upload-to-Zenodo
approach, to keep the git history itself usable for cloning.
