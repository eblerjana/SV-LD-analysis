

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
		vcf = "{results}/genotypes/genotypes-biallelic-svids.vcf.gz",
		tsv = "{results}/genotypes/genotypes-biallelic-svids.tsv"
	benchmark: 
		"{results}/genotypes/genotypes-biallelic-svids.benchmark"
	conda:
		"../envs/bcftools.yml"
	threads: 10
	resources:
		mem_mb = 50000,
		walltime = "10:00:00"
	shell:
		"""
		bcftools view -S {input.samples} --threads {threads} --force-samples {input.genotypes} | python3 workflow/scripts/annotate.py {output.tsv} | bgzip > {output.vcf}
		tabix -p vcf {output.vcf}
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
		"../envs/bcftools.yml"
	resources:
		mem_mb = 50000,
		walltime = "15:00:00"
	threads: 16
	shell:
		"""
		bcftools annotate -a {input.dbsnp} -c ID --collapse none --threads {threads} -Oz -o {output} {input.genotypes} &> {log}
		tabix -p vcf {output}
		"""

rule keep_unique_ids:
	"""
	The dnSNP VCF might contain multiple records with the
	same ID. Therefore, the same can occur in the annotated
	VCF. Plink complains about duplicated IDs, so this step
	drops variants corresponding to duplicated IDs.
	"""
	input:
		"{results}/genotypes/genotypes-biallelic-svids-annotated.vcf.gz"
	output:
		vcf = "{results}/genotypes/genotypes-biallelic-svids-annotated-unique.vcf.gz",
		tsv = "{results}/genotypes/genotypes-duplicated-IDs.tsv"
	benchmark:
		"{results}/genotypes/genotypes-biallelic-svids-annotated-unique.benchmark"
	log:
		"{results}/genotypes/genotypes-biallelic-svids-annotated-unique.log"
	conda:
		"../envs/bcftools.yml"
	resources:
		mem_mb = 60000,
		walltime = "15:00:00"
	params:
		tmpbase="."
	threads: 8
	shell:
		"""
		exec > {log} 2>&1
		set -x

		tmp=$(mktemp -d -p {params.tmpbase} sort_tmp.XXXXXX)
		trap 'rm -rf "$tmp"' EXIT

		bcftools query -f '%ID\\t%CHROM\\n' {input} | LC_ALL=C sort -u -S 8G --parallel={threads} -T \"$tmp\" | cut -f1 | LC_ALL=C uniq -d > {output.tsv}
		bcftools view -e 'ID=@{output.tsv}' -Oz -o {output.vcf} {input}
		bcftools index {output.vcf}
		"""


rule run_plink:
	"""
	Compute LD between all TARGET SNPs and SVs.
	"""
	input:
		target = TARGETS,
		genotypes = "{results}/genotypes/genotypes-biallelic-svids-annotated-unique.vcf.gz"
	output:
		"{results}/ld/ld-sv-targets.ld"
	log:
		"{results}/ld/ld-sv-targets.log"
	benchmark:
		"{results}/ld/ld-sv-targets.benchmark"
	params:
		outname = "{results}/ld/ld-sv-targets"
	conda:
		"../envs/plink.yml"
	resources:
		mem_mb = 80000,
		walltime = "15:00:00"
	threads: 10
	shell:
		"""
		plink --memory 70000 --threads {threads} --vcf {input.genotypes} --vcf-half-call m \
		--ld-snp-list {input.target} --r2 --with-freqs \
		--ld-window-kb 500 --ld-window 99999 --ld-window-r2 0.6 --out {params.outname}
		"""
