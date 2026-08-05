#!/usr/bin/env python3
"""Pick candidate species names from ITS/LSU remote BLAST hit tables.

Reads the outfmt-6(+qcovs+stitle) tables produced by 03_remote_blast.sh,
keeps hits above the identity/coverage thresholds, and prints the union of
top species names (ITS top hit, LSU top hit, then remaining ranked hits) -
one per line, most-supported first, deduplicated.
"""
import os
import sys

MIN_PID = float(os.environ.get("MIN_PIDENT", 90.0))
MIN_QCOV = float(os.environ.get("MIN_QCOV", 80.0))

# nt has plenty of non-taxonomic entries (PDB structures, environmental
# clones, mutant strain descriptions, ...) whose titles start with two
# words that look like "Genus species" but aren't - filter those out
# rather than trusting the first two tokens blindly.
NON_SPECIES_PREFIXES = {
    "chain", "uncultured", "unidentified", "mutant", "synthetic", "predicted",
    "cloning", "expression", "environmental", "fungal", "tpa:", "cdna", "clone",
}


def parse_binomial(stitle):
    toks = stitle.split()
    if len(toks) < 2:
        return None
    genus, species = toks[0], toks[1]
    if genus.lower() in NON_SPECIES_PREFIXES:
        return None
    if not genus.isalpha() or not genus[:1].isupper():
        return None
    if not species.isalpha() or not species.islower():
        return None
    return f"{genus} {species}"


def top_species(path):
    if not os.path.isfile(path):
        return []
    with open(path) as fh:
        rows = [l.rstrip("\n").split("\t") for l in fh if l.strip()]
    if not rows:
        return []
    rows.sort(key=lambda c: float(c[11]), reverse=True)  # bitscore desc
    species, seen = [], set()
    for c in rows[:20]:
        if len(c) < 14:
            continue
        pident, qcovs, stitle = float(c[2]), float(c[12]), c[13]
        if pident < MIN_PID or qcovs < MIN_QCOV:
            continue
        name = parse_binomial(stitle)
        if name and name not in seen:
            seen.add(name)
            species.append(name)
        if len(species) >= 3:
            break
    return species


def main():
    its_hits = top_species(sys.argv[1]) if len(sys.argv) > 1 else []
    lsu_hits = top_species(sys.argv[2]) if len(sys.argv) > 2 else []
    seen = set()
    for name in its_hits[:1] + lsu_hits[:1] + its_hits + lsu_hits:
        if name not in seen:
            seen.add(name)
            print(name)


if __name__ == "__main__":
    main()
