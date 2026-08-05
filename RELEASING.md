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

## A note specific to this repository (size) — ACTION REQUIRED before pushing

This repository is roughly 252 MiB, dominated by `saccharomyces_placement/` (~150 MB, mostly
`placement/combined_alignment.fasta` and per-isolate VCFs) and `yh156_assembly_and_synteny/`
(~101 MB, mostly the reference genome, draft assembly, and SyRI/synteny intermediates).

**`saccharomyces_placement/placement/combined_alignment.fasta` is ~135.4 MB (141,965,313
bytes) — this exceeds GitHub's 100 MB hard per-file limit and will be rejected on a plain
`git push`.** Before pushing to GitHub, either:
- Use [Git LFS](https://git-lfs.github.com/) for this file (and any other file that turns out
  to be >100 MB — none of the others currently are; the next-largest is the ~22.7 MB
  `YH156_vs_sv.delta`), or
- Exclude it from the pushed repository and note in `saccharomyces_placement/README.md` where
  it can be regenerated/obtained instead (it may be regenerable from the scripts in
  `saccharomyces_placement/placement/scripts/` plus the panel's public Zenodo deposits already
  cited in that package's README).

Do not `git add` this file until one of the above is decided — a large blob committed to
history is expensive to remove later even after switching to LFS.
