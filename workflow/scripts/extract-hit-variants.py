import sys

id_map_file = sys.argv[1]
hit_ids_file = sys.argv[2]

old_to_new_id = {}
hit_ids = set([])

with open(id_map_file, 'r') as id_map:
	for line in id_map:
		fields = line.strip().split()
		assert len(fields) == 2
		assert not fields[1] in old_to_new_id
		old_to_new_id[fields[1]] = fields[0]

with open(hit_ids_file, 'r') as hits:
	for line in hits:
		hit_ids.add(line.strip())

for line in sys.stdin:
	if line.startswith("#"):
		print(line.strip())
		continue

	chrom, pos, var_id, ref, alt, qual, filter, info, rest = line.split("\t", 8)


	# look up new ID (if any)
	new_id = old_to_new_id[var_id] if var_id in old_to_new_id else var_id

	# set INFO filed to "."
	info = "."

	if new_id in hit_ids:
		print("\t".join((chrom, pos, new_id, ref, alt, qual, filter, info, rest)), end="")
