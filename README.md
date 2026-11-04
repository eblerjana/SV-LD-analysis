# SV LD-analysis

Simple pipeline to compute LD between variants genotyped across a large cohort and given SNPs.

## How to run

Provide links to the input files in the `config/config.yml` file. The following fields are required:

```bash

# dbsnp VCF file with SNP variants
dbsnp: "/path/to/dbSNP-variants.vcf.gz"

# biallelic, multi-sample VCF with cohort
# genotypes. Must be relative to same reference
# as dbsnp VCF
genotypes: "/path/to/cohort-genotypes.vcf.gz"

# file with a list of dbSNP IDs specifying the
# SNPs to be used for LD computation. One ID
# per line.
targets: "/path/to/snp-list.tsv"

# a PED file specifying trio relationships.
# unrelated samples must be listed as well.
ped: "/path/to/ped-file.ped"

# name of the output folder
outname: "results" 
```
Then, the pipeline can be run with snakemake.
