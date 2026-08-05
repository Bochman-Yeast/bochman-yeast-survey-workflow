#!/bin/bash
#SBATCH --job-name=YH156_boundary_check
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=00:20:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=/N/scratch/bochman/yeast_id/results/YH156_v3_canu/vs_sversatilis/boundary_check_%j.log

source ~/.bashrc
export OPENBLAS_NUM_THREADS=1
conda activate yeast-id
cd /N/scratch/bochman/yeast_id/results/YH156_v3_canu/vs_sversatilis

python3 << 'PYEOF'
import re
from Bio import SeqIO

pseudo_fasta = "YH156_pseudochroms_sv.fasta"
syri_out = "YH156_sv_syri.out"

boundaries = {}
for rec in SeqIO.parse(pseudo_fasta, "fasta"):
    seq = str(rec.seq)
    boundaries[rec.id] = [(m.start(), m.end()) for m in re.finditer("N+", seq)]
    print(f"{rec.id}: {len(boundaries[rec.id])} contig-junction N-gaps found")

window = 2000
results = {}
with open(syri_out) as f:
    for line in f:
        cols = line.rstrip("\n").split("\t")
        if len(cols) < 11:
            continue
        achr, astart, aend, aseq, bseq, bchr, bstart, bend, vid, pid, antype = cols[:11]
        if antype in ("SNP", "INS", "DEL"):
            continue
        try:
            bstart_i = int(bstart)
            bend_i = int(bend)
        except ValueError:
            continue
        near_boundary = False
        for (bs, be) in boundaries.get(bchr, []):
            if (abs(bstart_i - bs) <= window or abs(bstart_i - be) <= window or
                abs(bend_i - bs) <= window or abs(bend_i - be) <= window):
                near_boundary = True
                break
        results.setdefault(antype, {"near": 0, "far": 0})
        if near_boundary:
            results[antype]["near"] += 1
        else:
            results[antype]["far"] += 1

print("\n=== Structural call proximity to contig junctions (within 2kb) ===")
for antype, counts in sorted(results.items(), key=lambda x: -(x[1]["near"]+x[1]["far"])):
    total = counts["near"] + counts["far"]
    pct = 100 * counts["near"] / total if total else 0
    print(f"{antype}: {total} total, {counts['near']} near a contig junction ({pct:.1f}%), {counts['far']} interior")
PYEOF
