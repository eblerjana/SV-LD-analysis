import sys

SV_TYPES = ("INS", "DEL", "COMPLEX")

def is_sv(var_id):
	"""
	Check if variant is SV based on ID.
	"""	
	if var_id.startswith(SV_TYPES):
		# check variant length to see if SV
		var_len = int(var_id.strip().split('-')[-1])
		if var_len >= 50:
			return True
	return False
		

outfile_name = sys.argv[1]
outfile2_name = sys.argv[2]

total_hits = 0
sv_hits = 0
other_hits = 0

with open(outfile_name, 'w') as outfile, open(outfile2_name, 'w') as outfile_ID:

	for line in sys.stdin:
		fields = line.strip().split()
		if not fields:
			continue
		if (fields[0] == "CHR_A"):
			continue

		id_a = fields[2]
		id_b = fields[6]

		is_sv_a = is_sv(id_a)
		is_sv_b = is_sv(id_b)

		if is_sv_a or is_sv_b:
			outfile.write(line)
			outfile_ID.write(id_b + '\n')
			sv_hits += 1
		else:
			other_hits += 1
		total_hits += 1

# print stats
print("number of SV hits:\t" + str(sv_hits))
print("number of other hits:\t" + str(other_hits))
print("number of total hits:\t" + str(total_hits))
