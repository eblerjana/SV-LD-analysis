# Data used for grant analysis


## dbSNP variants

A dbsnp VCF file for CHM13 was downloaded on 03.11.2026 from:

https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/liftover/chm13v2.0_dbSNPv155.vcf.gz


## target SNPs

The dbSNP IDs of SNPs that are associated with diabetes phenotypes were extracted from Supplementary Table 4 of this paper: https://www.nature.com/articles/s41586-024-07019-6#Sec27


## genotypes

The HPRC2 filtered PanGenie genotypes for the 1000 Genomes samples were used: https://s3-us-west-2.amazonaws.com/human-pangenomics/pangenomes/scratch/2026_03_30_pangenie/pangenie_all-samples_filtered.vcf.gz


## PED file

A PED file defining all 1000 Genomes trios (and unrelated samples) was used, same as for the HPRC2 companion paper: https://github.com/eblerjana/hprc2-companion/blob/main/genotyping-pipeline/1kg-hprc2-sample-sheet-withONT.tsv
