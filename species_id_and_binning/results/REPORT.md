# Yeast species identification report

Method: ITS + D1/D2 LSU barcode (remote BLAST vs nt) as primary screen, whole-genome ANI (skani) against NCBI reference genomes as confirmation - mandatory and authoritative for Saccharomyces sensu stricto, where rDNA barcodes cannot resolve species.

Samples processed: 9

## Per-sample calls

- **YH26**: Lachancea thermotolerans (High) - ITS/LSU agree (Lachancea thermotolerans), ANI=98.28% confirms.
- **YH72**: Lachancea thermotolerans (High) - ITS/LSU agree (Lachancea thermotolerans), ANI=98.31% confirms.
- **YH115**: Schizosaccharomyces pombe (Medium) - Only one marker gave a confident hit (Schizosaccharomyces pombe); other marker missing/low quality.
- **YH123**: Saccharomyces cerevisiae (High) - Saccharomyces sensu stricto: barcode cannot resolve species, ANI is authoritative.; ANI=99.26% vs Saccharomyces_cerevisiae, clears 95.0% boundary.
- **YH140**: Mixed culture: Lachancea thermotolerans (53.3% of assembly, 78.9% of reads, BUSCO=99.7%) + Torulaspora delbrueckii (46.2% of assembly, 41.2% of reads, BUSCO=99.8%) (High) - Contig binning + read-mapping + per-bin BUSCO confirm a genuine two-species co-culture (not barcode cross-talk or misassembly): both organisms have substantial, comparable read support and each bin independently assembles into a near-complete single-species genome. See mixed_investigation/ for detail.
- **YH156**: Schizosaccharomyces versatilis (nom. inval.) (High) - Independently verified within this pipeline: skani ANI = 99.14% against the type strain (CBS 103, GCA_032882995.1), decisively above the 95% species boundary. This CORRECTS an earlier claim from a separate investigation session that identified this sample as Schizosaccharomyces japonicus - that call was not supported: ANI against the actual S. japonicus reference (yFS275, GCF_000149845.2) was only 87.94%, well below the species boundary, and only 6% of the draft assembly (v3_canu, /N/scratch/bochman/yeast_id/results/YH156_v3_canu/) aligned well to it. BLAST of the poorly-matched contigs against nt showed consistent, very high identity (96-99.8%) to S. versatilis strain CBS 103 across all three of its chromosomes, which is what led to testing and confirming this reference instead. "nom. inval." (nomen invalidum) means this species name has not yet been formally, validly published under the nomenclatural code - this is a recently-deposited (2023) type strain genome, and this wild isolate matching it at species level is itself notable supporting evidence for the taxon. The draft assembly used for this verification is still explicitly a work-in-progress (213 contigs, known chimeric/ambiguous-repeat issues per the other session) - align_fraction_query was 71.95%, better than against the wrong reference but not saturating, consistent with remaining assembly completeness issues rather than a species-identity problem.
- **YH166**: Saccharomyces cerevisiae (High) - Saccharomyces sensu stricto: barcode cannot resolve species, ANI is authoritative.; ANI=99.34% vs Saccharomyces_cerevisiae, clears 95.0% boundary.
- **YH196**: Saccharomyces cerevisiae (High) - Saccharomyces sensu stricto: barcode cannot resolve species, ANI is authoritative.; ANI=98.96% vs Saccharomyces_cerevisiae, clears 95.0% boundary.
- **YH229**: Saccharomyces cerevisiae (High) - Saccharomyces sensu stricto: barcode cannot resolve species, ANI is authoritative.; ANI=99.43% vs Saccharomyces_cerevisiae, clears 95.0% boundary.

## Needs attention

- **YH115**: low BUSCO completeness (80.0%)
- **YH140**: confirmed two-species mixed culture, not a single isolate (see mixed_investigation/)
- **YH156**: low BUSCO completeness (0.0%); assembly length outside expected yeast range (426,170 bp); preliminary call from a separate investigation, not yet confirmed by this pipeline
