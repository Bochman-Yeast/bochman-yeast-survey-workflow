#!/usr/bin/env python3
import sys, math
import numpy as np
import pandas as pd
from Bio import Phylo
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.lines as mlines
from matplotlib.collections import LineCollection
from matplotlib.patches import Wedge

sys.setrecursionlimit(10000)

PROJ = "/N/scratch/bochman/yeast_id/scerevisiae_popgen"
TARGETS = ["YH123", "YH166", "YH196", "YH229", "DoF1"]

SUPERCLADE_COLOR = {
    "S1. Wine": "#b3223c",
    "S2. Beer": "#d99a1b",
    "S3. Asian Fermentation": "#1f8f6b",
    "S4. Wild": "#8a6d1f",
}
SUPERCLADE_LABEL = {
    "S1. Wine": "Wine",
    "S2. Beer": "Beer",
    "S3. Asian Fermentation": "Asian Fermentation",
    "S4. Wild": "Wild",
}
DEFAULT_COLOR = "#8a857a"
BRANCH_COLOR = "#8a857a"
TARGET_COLOR = "#1d4fd8"
BG = "#ffffff"
INK = "#151815"
MIN_RUN_LEN = 6

meta = pd.read_csv(f"{PROJ}/metadata/panel_isolates.tsv", sep="\t")
sc_lookup = meta.set_index("StandardizedName")["SuperClade"].to_dict()

def get_superclade(name):
    sc = sc_lookup.get(name)
    if sc is None or (isinstance(sc, float) and pd.isna(sc)):
        return None
    return sc if sc in SUPERCLADE_COLOR else None

print("Reading tree...", file=sys.stderr)
tree = Phylo.read(f"{PROJ}/placement/combined_tree.nwk", "newick")
terminals = tree.get_terminals()
n = len(terminals)
print(f"{n} tips", file=sys.stderr)

tip_angle = {t: 2 * math.pi * i / n for i, t in enumerate(terminals)}

parent_of = {}
for clade in tree.find_clades():
    for child in clade.clades:
        parent_of[child] = clade

print("Computing depths (cladogram / unit branch lengths)...", file=sys.stderr)
depths = tree.depths(unit_branch_lengths=True)

print("Computing angles...", file=sys.stderr)
node_angle = {}
def compute_angle(clade):
    if clade in node_angle:
        return node_angle[clade]
    if clade.is_terminal():
        a = tip_angle[clade]
    else:
        a = sum(compute_angle(c) for c in clade.clades) / len(clade.clades)
    node_angle[clade] = a
    return a
compute_angle(tree.root)

print("Computing dominant superclade per subtree...", file=sys.stderr)
leaf_sc = {t: get_superclade(t.name) for t in terminals}
dominant = {}
def compute_dominant(clade):
    if clade in dominant:
        return dominant[clade]
    if clade.is_terminal():
        d = leaf_sc.get(clade)
    else:
        child_doms = set(compute_dominant(c) for c in clade.clades)
        d = child_doms.pop() if len(child_doms) == 1 else None
    dominant[clade] = d
    return d
compute_dominant(tree.root)

def polar_to_xy(r, theta):
    return r * math.cos(theta), r * math.sin(theta)

print("Finding contiguous runs per superclade...", file=sys.stderr)
sc_sequence = [leaf_sc.get(t) for t in terminals]
runs = []
start = 0
for i in range(1, n):
    if sc_sequence[i] != sc_sequence[i - 1]:
        runs.append((sc_sequence[i - 1], start, i - 1))
        start = i
runs.append((sc_sequence[n - 1], start, n - 1))

sc_runs = {sc: [] for sc in SUPERCLADE_COLOR}
for sc, s, e in runs:
    if sc not in SUPERCLADE_COLOR:
        continue
    length = e - s + 1
    if length >= MIN_RUN_LEN:
        sc_runs[sc].append((s, e, length))

UNASSIGNED_MIN_RUN_LEN = 10
unassigned_runs = []
for sc, s, e in runs:
    if sc is not None:
        continue
    length = e - s + 1
    if length >= UNASSIGNED_MIN_RUN_LEN:
        unassigned_runs.append((s, e, length))

wedge_pieces = {}
best_piece = {}
for sc, run_list in sc_runs.items():
    pieces = []
    for s, e, length in run_list:
        lo = tip_angle[terminals[s]]
        hi = tip_angle[terminals[e]]
        outer_r = max(depths[terminals[i]] for i in range(s, e + 1)) * 1.02
        pieces.append((lo, hi, outer_r, length))
    wedge_pieces[sc] = pieces
    if pieces:
        best_piece[sc] = max(pieces, key=lambda p: p[3])
    print(f"  {sc}: {len(pieces)} block(s), sizes {[p[3] for p in pieces]}", file=sys.stderr)

print("Drawing...", file=sys.stderr)
fig = plt.figure(figsize=(24, 24), facecolor=BG)
ax = fig.add_subplot(111)
ax.set_facecolor(BG)

label_anchor_points = []

for sc, pieces in wedge_pieces.items():
    color = SUPERCLADE_COLOR[sc]
    for lo, hi, outer_r, length in pieces:
        w = Wedge((0, 0), outer_r, math.degrees(lo), math.degrees(hi),
                   facecolor=color, alpha=0.10, edgecolor="none", zorder=0)
        ax.add_patch(w)
    if sc in best_piece:
        lo, hi, outer_r, length = best_piece[sc]
        mid = (lo + hi) / 2
        label_r = outer_r * 1.22
        lx, ly = polar_to_xy(label_r, mid)
        deg = math.degrees(mid) % 360
        if deg > 180:
            deg -= 360
        rot = deg if -90 < deg < 90 else deg + 180
        ax.text(lx, ly, SUPERCLADE_LABEL[sc], fontsize=30, fontweight="bold", color=color,
                ha="center", va="center", rotation=rot, rotation_mode="anchor", zorder=10)
        label_anchor_points.append((lx, ly))

for s, e, length in unassigned_runs:
    lo = tip_angle[terminals[s]]
    hi = tip_angle[terminals[e]]
    outer_r = max(depths[terminals[i]] for i in range(s, e + 1)) * 1.02
    w = Wedge((0, 0), outer_r, math.degrees(lo), math.degrees(hi),
               facecolor=DEFAULT_COLOR, alpha=0.10, edgecolor="none", zorder=0)
    ax.add_patch(w)
print(f"  Unassigned/Admixed: {len(unassigned_runs)} block(s), sizes {[r[2] for r in unassigned_runs]}", file=sys.stderr)

colored_segs = {sc: [] for sc in SUPERCLADE_COLOR}
grey_segs = []
for clade in tree.find_clades():
    if clade not in parent_of:
        continue
    parent = parent_of[clade]
    r_parent, r_child = depths[parent], depths[clade]
    theta = node_angle[clade]
    x0, y0 = polar_to_xy(r_parent, theta)
    x1, y1 = polar_to_xy(r_child, theta)
    d = dominant[clade]
    if d in colored_segs:
        colored_segs[d].append([(x0, y0), (x1, y1)])
    else:
        grey_segs.append([(x0, y0), (x1, y1)])

grey_arcs, colored_arcs = [], {sc: [] for sc in SUPERCLADE_COLOR}
for clade in tree.find_clades():
    if clade.is_terminal():
        continue
    children_angles = [node_angle[c] for c in clade.clades]
    if len(children_angles) < 2:
        continue
    theta1, theta2 = min(children_angles), max(children_angles)
    r = depths[clade]
    thetas = np.linspace(theta1, theta2, max(4, int(20 * (theta2 - theta1) / (2 * math.pi)) + 4))
    pts = [(r * math.cos(t), r * math.sin(t)) for t in thetas]
    d = dominant[clade]
    if d in colored_arcs:
        colored_arcs[d].append(pts)
    else:
        grey_arcs.append(pts)

ax.add_collection(LineCollection(grey_segs, colors=BRANCH_COLOR, linewidths=0.5, alpha=0.55, zorder=1))
ax.add_collection(LineCollection(grey_arcs, colors=BRANCH_COLOR, linewidths=0.5, alpha=0.55, zorder=1))
for sc, segs in colored_segs.items():
    ax.add_collection(LineCollection(segs, colors=SUPERCLADE_COLOR[sc], linewidths=1.3, alpha=0.9, zorder=2))
for sc, arcs in colored_arcs.items():
    ax.add_collection(LineCollection(arcs, colors=SUPERCLADE_COLOR[sc], linewidths=1.3, alpha=0.9, zorder=2))

tip_x, tip_y, tip_colors = [], [], []
for t in terminals:
    if t.name in TARGETS:
        continue
    r, theta = depths[t], node_angle[t]
    x, y = polar_to_xy(r, theta)
    tip_x.append(x)
    tip_y.append(y)
    sc = leaf_sc.get(t)
    tip_colors.append(SUPERCLADE_COLOR.get(sc, DEFAULT_COLOR))
ax.scatter(tip_x, tip_y, s=6, c=tip_colors, alpha=0.9, zorder=3, linewidths=0)

global_max_r = max(depths.values())
label_offset = global_max_r * 0.20

target_info = []
for name in TARGETS:
    match = [t for t in terminals if t.name == name]
    if not match:
        continue
    t = match[0]
    r, theta = depths[t], node_angle[t]
    target_info.append([name, theta, r, theta])

target_info.sort(key=lambda x: x[1])
min_gap = math.radians(6.0)
for _pass in range(200):
    moved = False
    for i in range(len(target_info) - 1):
        a, b = target_info[i], target_info[i + 1]
        gap = b[3] - a[3]
        if gap < min_gap:
            push = (min_gap - gap) / 2
            a[3] -= push
            b[3] += push
            moved = True
    if not moved:
        break

for name, theta_tip, r_tip, theta_label in target_info:
    x_tip, y_tip = polar_to_xy(r_tip, theta_tip)
    r_label = r_tip + label_offset
    x_lab, y_lab = polar_to_xy(r_label, theta_label)
    ax.plot(x_tip, y_tip, marker="*", markersize=22, color=TARGET_COLOR,
            markeredgecolor="white", markeredgewidth=1.2, zorder=6)
    ax.annotate("", xy=(x_tip, y_tip), xytext=(x_lab, y_lab),
                arrowprops=dict(arrowstyle="-", color=TARGET_COLOR, lw=1.4, alpha=0.85,
                                 shrinkA=2, shrinkB=6, connectionstyle="arc3,rad=0.0"),
                zorder=5)
    deg = math.degrees(theta_label) % 360
    if deg > 180:
        deg -= 360
    rot = deg if -90 < deg < 90 else deg + 180
    ax.annotate(name, xy=(x_lab, y_lab), fontsize=17, fontweight="bold", color=INK,
                ha="center", va="center", zorder=7, rotation=rot, rotation_mode="anchor",
                bbox=dict(boxstyle="round,pad=0.22", facecolor="white", edgecolor=TARGET_COLOR, linewidth=1.3, alpha=0.95))
    label_anchor_points.append((x_lab, y_lab))

all_x = [p[0] for segs in list(colored_segs.values()) + [grey_segs] for seg in segs for p in seg]
all_y = [p[1] for segs in list(colored_segs.values()) + [grey_segs] for seg in segs for p in seg]
all_x += tip_x + [p[0] for p in label_anchor_points]
all_y += tip_y + [p[1] for p in label_anchor_points]
x_min, x_max = min(all_x), max(all_x)
y_min, y_max = min(all_y), max(all_y)
pad_x = (x_max - x_min) * 0.06
pad_y = (y_max - y_min) * 0.06
ax.set_xlim(x_min - pad_x, x_max + pad_x)
ax.set_ylim(y_min - pad_y, y_max + pad_y)
ax.set_aspect("equal")
ax.axis("off")

legend_elems = [mpatches.Patch(color=c, label=SUPERCLADE_LABEL[k]) for k, c in SUPERCLADE_COLOR.items()]
legend_elems.append(mpatches.Patch(color=DEFAULT_COLOR, label="Unassigned / Admixed"))
legend_elems.append(mlines.Line2D([0], [0], marker="*", color=BG, markerfacecolor=TARGET_COLOR,
                                   markeredgecolor="white", markersize=20, label="This study (5 isolates)"))
ax.legend(handles=legend_elems, loc="upper left", fontsize=18, frameon=False, bbox_to_anchor=(0.0, 1.0))

ax.set_title("Phylogenomic placement of 5 Bloomington isolates among 3,034 S. cerevisiae genomes\n"
             "(Loegler et al. 2024 panel + this study; FastTree, 46,705 shared SNPs)",
             fontsize=20, color=INK, pad=14)

plt.tight_layout()
plt.savefig(f"{PROJ}/placement/circular_tree.png", dpi=170, facecolor=fig.get_facecolor())
plt.savefig(f"{PROJ}/placement/circular_tree.pdf", facecolor=fig.get_facecolor())
print("Saved circular_tree.png and circular_tree.pdf", file=sys.stderr)
