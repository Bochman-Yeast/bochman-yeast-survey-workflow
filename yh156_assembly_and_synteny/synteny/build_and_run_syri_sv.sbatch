#!/bin/bash
#SBATCH --job-name=YH156_syri_sv
#SBATCH --account=r02049
#SBATCH --partition=general
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --output=/N/scratch/bochman/yeast_id/results/YH156_v3_canu/vs_sversatilis/syri_sv_%j.log

source ~/.bashrc
export OPENBLAS_NUM_THREADS=1
cd /N/scratch/bochman/yeast_id/results/YH156_v3_canu/vs_sversatilis

REF=/N/scratch/bochman/yeast_id/refs/Schizosaccharomyces_versatilis/genome.fna
QRY=/N/scratch/bochman/yeast_id/results/YH156_v3_canu/medaka_polish/consensus.fasta

conda activate yeast-id

python3 << 'PYEOF'
from collections import defaultdict
from Bio import SeqIO
from Bio.Seq import Seq

paf = "dechim_vs_sv.paf"
qry_fasta = "/N/scratch/bochman/yeast_id/results/YH156_v3_canu/medaka_polish/consensus.fasta"

agg = defaultdict(lambda: {'total': 0, 'mintstart': None, '+': 0, '-': 0})
with open(paf) as f:
    for line in f:
        cols = line.rstrip("\n").split("\t")
        q, strand, chrom = cols[0], cols[4], cols[5]
        tstart, tend = int(cols[7]), int(cols[8])
        alnlen = tend - tstart
        key = (q, chrom)
        agg[key]['total'] += alnlen
        agg[key][strand] += alnlen
        if agg[key]['mintstart'] is None or tstart < agg[key]['mintstart']:
            agg[key]['mintstart'] = tstart

best = {}
for (q, chrom), d in agg.items():
    if q not in best or d['total'] > best[q][1]:
        best[q] = (chrom, d['total'], d['mintstart'], d['+'], d['-'])

groups = defaultdict(list)
for q, (chrom, total, tstart, plus_bp, minus_bp) in best.items():
    groups[chrom].append((tstart, q, plus_bp, minus_bp))
for chrom in groups:
    groups[chrom].sort()

seqs = SeqIO.to_dict(SeqIO.parse(qry_fasta, "fasta"))
spacer = "N" * 100
placed = set()
flipped_contigs = []

with open("YH156_pseudochroms_sv.fasta", "w") as out:
    for chrom, members in groups.items():
        parts = []
        for tstart, q, plus_bp, minus_bp in members:
            seq = str(seqs[q].seq)
            if minus_bp > plus_bp:
                seq = str(Seq(seq).reverse_complement())
                flipped_contigs.append(q)
            parts.append(seq)
            placed.add(q)
        pseudo = spacer.join(parts)
        out.write(f">{chrom}\n")
        for i in range(0, len(pseudo), 60):
            out.write(pseudo[i:i+60] + "\n")
        print(f"{chrom}: {len(members)} contigs, {len(pseudo)} bp")

unplaced = [q for q in seqs if q not in placed]
print(f"\nPlaced {len(placed)} of {len(seqs)} contigs into 3 pseudo-chromosomes")
print(f"Unplaced ({len(unplaced)}): {unplaced}")
print(f"\nReoriented {len(flipped_contigs)} of {len(placed)} placed contigs to match reference strand")
PYEOF

seqkit stats -a YH156_pseudochroms_sv.fasta
conda deactivate

conda activate synteny
nucmer --maxmatch -c 100 -b 500 -l 50 -t 8 -p YH156_vs_sv $REF YH156_pseudochroms_sv.fasta
delta-filter -m -i 90 -l 100 YH156_vs_sv.delta > YH156_vs_sv.filtered.delta
show-coords -THrd YH156_vs_sv.filtered.delta > YH156_vs_sv.filtered.coords

syri -c YH156_vs_sv.filtered.coords -d YH156_vs_sv.filtered.delta -r $REF -q YH156_pseudochroms_sv.fasta --dir . --prefix YH156_sv_ --nc 4
