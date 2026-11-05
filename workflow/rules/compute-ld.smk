

rule extract_unrelated_samples:
	"""
	Create a list with all unrelated samples
	in the VCF.
	"""
	input:
		PED
	output:
		"{results}/unrelated-samples.tsv"
	shell:
		"""
		awk '$1 !~ /^#/ && $3==\"0\" && $4==\"0\" {{ print $2 }}' {input} > {output}
		"""

rule prepare_variant_ids:
	"""
	Make sure that there are variant IDs assigned to
	all SVs. Set all other variant IDs to missing.
	"""
	input:
		genotypes = GENOTYPES,
		samples = "{results}/unrelated-samples.tsv"
	output:
		"{results}/genotypes/genotypes-biallelic-svids.vcf.gz"
	benchmark: 
		"{results}/genotypes/genotypes-biallelic-svids.benchmark"
	conda:
		"../envs/bcftools.yml"
	resources:
		mem_mb = 50000,
		walltime = "05:00:00"
	shell:
		"""
		bcftools view -S {input.samples} --force-samples {input.genotypes} | python3 workflow/scripts/annotate.py | bgzip > {output}
		tabix -p vcf {output}
		"""

rule annotate:
	"""
	Annotate SNPs with dbSNP variant IDs.
	"""
	input:
		genotypes = "{results}/genotypes/genotypes-biallelic-svids.vcf.gz",
		dbsnp = DBSNP
	output:
		"{results}/genotypes/genotypes-biallelic-svids-annotated.vcf.gz"
	log:
		"{results}/genotypes/genotypes-biallelic-svids-annotated.log"
	benchmark:
		"{results}/genotypes/genotypes-biallelic-svids-annotated.benchmark"
	conda:
		"../envs/gatk4.yml"
	resources:
		mem_mb = 50000,
		walltime = "5:00:00"
	shell:
		"""
		gatk VariantAnnotator --variant {input.genotypes} --output {output} --dbsnp {input.dbsnp} &> {log}
		"""


rule add_tags:
	"""
	Assign AN, AC and AF tags to each variant.
	"""
	input:
		"{results}/genotypes/genotypes-biallelic-svids-annotated.vcf.gz"
	output:
		"{results}/genotypes/genotypes-biallelic-svids-annotated-afs.vcf.gz"
	log:
		"{results}/genotypes/genotypes-biallelic-svids-annotated-afs.log"
	benchmark:
		"{results}/genotypes/genotypes-biallelic-svids-annotated-afs.benchmark"
	conda:
		"../envs/bcftools.yml"
	resources:
		mem_mb = 50000,
		walltime = "2:00:00"
	shell:
		"""
		bcftools +fill-tags {input} -Oz -o {output} -- -t AN,AC,AF &> {log}
		"""


rule run_plink:
	"""
	Compute LD between all TARGET SNPs and SVs.
	"""
	input:
		target = TARGETS,
		genotypes = "{results}/genotypes/genotypes-biallelic-svids-annotated-afs.vcf.gz"
	output:
		"{results}/ld/ld-sv-targets.ld.gz"
	log:
		"{results}/ld/ld-sv-targets.log"
	benchmark:
		"{results}/ld/ld-sv-targets.benchmark"
	params:
		outname = "{results}/ld/ld-sv-targets"
	conda:
		"../envs/plink.yml"
	resources:
		mem_mb = 50000,
		walltime = "2:00:00"
	threads: 5
	shell:
		"""
		plink --threads {threads} --vcf {input.genotypes} --vcf-half-call m \
		--ld-snp-list {input.target} --r2 --with-freqs \
		--ld-window-kb 500 --ld-window 99999 --ld-window-r2 0.6 --out {params.outname}
		"""
