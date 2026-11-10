import sys

def get_variant_type(ref_allele, alt_allele):
	"""
	Determine variant type and length
	"""
	len_ref = len(ref_allele)
	len_alt = len(alt_allele)
	vartype = None
	varlen = None
	if len_ref == 1:
		if len_alt > 1:
			vartype = 'INS'
			varlen = abs(len_ref - len_alt)
		else:
			vartype = 'SNV'
			varlen = 1
	else:
		if len_alt == 1:
			vartype = 'DEL'
			varlen = abs(len_ref - len_alt)
		else:
			vartype = 'COMPLEX'
			varlen = max(len_ref, len_alt)
	return varlen, vartype


outname = sys.argv[1]

with open(outname, 'w') as outtsv:

	varidx = 0
	for line in sys.stdin:
		if line.startswith('##'):
			print(line[:-1])
			continue
		if line.startswith('#'):
			# define symbolic alleles
			print('##ALT=<ID=INS,Description=\"Insertion (allele shortened for plink)\">')
			print('##ALT=<ID=DEL,Description=\"Deletion (allele shortened for plink)\">')
			print('##ALT=<ID=COMPLEX,Description=\"Other structural variant (allele shortened for plink)\">')
			print(line[:-1])
			continue

		fields = line.strip().split()

		# make sure VCF is biallelic
		is_biallelic = len(fields[4].split(',')) == 1
		if not is_biallelic:
			raise RuntimeError("The VCF with genotypes needs to be biallelic.")
			sys.exit(1)

		varlen, vartype = get_variant_type(fields[3], fields[4])
		new_id = vartype + str(varidx) + "-" + str(varlen)

		if varlen >= 50:
			info = { i.split('=')[0] : i.split('=')[1] for i in fields[7].split(';') if '=' in i }
			if 'ID' in info:
				outtsv.write("\t".join([new_id, info['ID']]) + "\n")
			fields[2] = new_id

			# make VCF symbolic
			fields[3] = fields[3][0]
			fields[4] = "<" + vartype + ">"
		else:
			fields[2] = new_id
		varidx += 1

		# drop INFO field to keep VCF small
		fields[7] = "."

		print('\t'.join(fields))
