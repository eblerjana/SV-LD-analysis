import sys

varidx = 0
for line in sys.stdin:
	if line.startswith('#'):
		print(line[:-1])
		continue
	fields = line.strip().split()
	info = { i.split('=')[0] : i.split('=')[1] for i in fields[7].split(';') if '=' in i }

	# make sure VCF is biallelic
	is_biallelic = len(fields[4].split(',')) == 1

	if not is_biallelic:
		raise RuntimeError("The VCF with genotypes needs to be biallelic.")
		sys.exit(1)

	varlen = abs(len(fields[3]) - len(fields[4]))
	if 'ID' in info:
		varid = info['ID']
	else:
		varid = "variant" + str(varidx)

	if varlen >= 50:
		fields[2] = varid
	else:
		fields[2] = '.'
	print('\t'.join(fields))
	varidx += 1

