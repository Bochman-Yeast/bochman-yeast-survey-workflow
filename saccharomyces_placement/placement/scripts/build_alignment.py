#!/usr/bin/env python3
import sys

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"

IUPAC = {
    frozenset(['A','G']): 'R', frozenset(['C','T']): 'Y',
    frozenset(['G','C']): 'S', frozenset(['A','T']): 'W',
    frozenset(['G','T']): 'K', frozenset(['A','C']): 'M',
}
def het_code(a, b):
    if a == b:
        return a
    return IUPAC.get(frozenset([a,b]), 'N')

def gt_to_char(gt, ref, alt):
    if gt in ("./.", ".|.", "."):
        return 'N'
    alleles = gt.replace('|','/').split('/')
    try:
        idxs = [int(a) for a in alleles]
    except ValueError:
        return 'N'
    bases = []
    for i in idxs:
        if i == 0:
            bases.append(ref)
        elif i == 1:
            bases.append(alt)
        else:
            return 'N'
    if len(bases) == 1:
        bases = bases * 2
    if len(bases[0]) != 1 or len(bases[1]) != 1:
        return 'N'
    return het_code(bases[0], bases[1])

with open(f"{PROJ}/placement/panel_sample_names.txt") as f:
    panel_samples = [l.strip() for l in f]

new_samples = ["YH123", "YH166", "YH196", "YH229", "DoF1"]
all_samples = panel_samples + new_samples
seqs = {s: [] for s in all_samples}

new_gt = {}
with open(f"{PROJ}/placement/newsamples_matrix.tsv") as f:
    header = f.readline()
    for line in f:
        parts = line.rstrip("\n").split("\t")
        chrom, pos = parts[0], parts[1]
        new_gt[(chrom, pos)] = parts[2:2+len(new_samples)]

n_sites = 0
skipped = 0
with open(f"{PROJ}/placement/panel_genotypes_subset.tsv") as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        chrom, pos, ref, alt = parts[0], parts[1], parts[2], parts[3]
        gts = parts[4:]
        if len(ref) != 1 or ',' in alt or len(alt) != 1:
            skipped += 1
            continue
        for s, gt in zip(panel_samples, gts):
            seqs[s].append(gt_to_char(gt, ref, alt))
        key = (chrom, pos)
        if key in new_gt:
            for s, gt in zip(new_samples, new_gt[key]):
                seqs[s].append(gt_to_char(gt, ref, alt))
        else:
            for s in new_samples:
                seqs[s].append('N')
        n_sites += 1
        if n_sites % 10000 == 0:
            print(f"  ...{n_sites} sites processed", file=sys.stderr)

print(f"Built alignment: {n_sites} sites used, {skipped} skipped (indel/multiallelic), {len(all_samples)} samples", file=sys.stderr)

with open(f"{PROJ}/placement/combined_alignment.fasta", "w") as out:
    for s in all_samples:
        out.write(f">{s}\n")
        out.write("".join(seqs[s]) + "\n")

print("DONE", file=sys.stderr)
