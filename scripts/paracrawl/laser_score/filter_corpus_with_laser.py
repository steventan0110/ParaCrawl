import argparse

def score_filter(args):
	ret_en = ""
	ret_other = ""
	with open(args.input, 'r') as f:
		bitext = f.read()
	for text in bitext.split('\n'):
		if len(text) < 1:
			continue
		score, en, other = text.split('\t')
		if float(score) >= args.threshold:
			ret_en += en
			ret_en += '\n'
			ret_other += other
			ret_other += '\n'
	with open(f'{args.output}-{args.threshold}.en', 'w') as f1:
		f1.write(ret_en)

	with open(f'{args.output}-{args.threshold}.{args.lang}', 'w') as f2:
		f2.write(ret_other)


def line_filter(args):
	ret_en = ""
	ret_other = ""
	m = dict()
	with open(args.input, 'r') as f:
		bitext = f.read()
	for text in bitext.split('\n'):
		if len(text) < 1: continue
		score, en, other = text.split('\t')
		if float(score) == 0: continue # ignore worst samples
		m[(en, other)] = float(score)
	sorted_map = sorted(m.items(), key=lambda x: x[1], reverse=True)
	assert int(args.threshold) < len(sorted_map)
	for i in range(int(args.threshold)):
		ret_en += sorted_map[i][0][0]
		ret_en += '\n'
		ret_other += sorted_map[i][0][1]
		ret_other += '\n'

	with open(f'{args.output}-{int(args.threshold)}.en', 'w') as f1:
		f1.write(ret_en)

	with open(f'{args.output}-{int(args.threshold)}.{args.lang}', 'w') as f2:
		f2.write(ret_other)

def word_filter(args):
	ret_en = ""
	ret_other = ""
	m = dict()
	with open(args.input, 'r') as f:
		bitext = f.read()
	for text in bitext.split('\n'):
		if len(text) < 1: continue
		score, en, other = text.split('\t')
		if float(score) == 0: continue # ignore worst samples
		m[(en, other)] = float(score)
	sorted_map = sorted(m.items(), key=lambda x: x[1], reverse=True)
	# threshold use small number like 2,3,4
	count = 0
	i = 0
	while count < int(args.threshold)*1000000:
		ret_en += sorted_map[i][0][0]
		ret_en += '\n'
		ret_other += sorted_map[i][0][1]
		ret_other += '\n'
		count += len(sorted_map[i][0][0].split(' '))
		i += 1


	with open(f'{args.output}-{int(args.threshold)}.en', 'w') as f1:
		f1.write(ret_en)

	with open(f'{args.output}-{int(args.threshold)}.{args.lang}', 'w') as f2:
		f2.write(ret_other)

def main(args):
	if args.mode == 'score':
		# using score as threshold to filter data
		score_filter(args)
	elif args.mode == 'line':
		line_filter(args)
	else:
		word_filter(args)

if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Use Laser score file to output the bilingual dataset')
	parser.add_argument('--input', required=True, default='.', type=str, help='laser score file')
	parser.add_argument('--output', required=True, default='.', type=str, help='output bilingual file for NMT')
	parser.add_argument('--threshold', default=0.9, type=float)
	parser.add_argument('--lang', required=True, type=str)
	parser.add_argument('--mode', required=True, type=str, choices={'line', 'score', 'word'})
	args = parser.parse_args()
	main(args)
