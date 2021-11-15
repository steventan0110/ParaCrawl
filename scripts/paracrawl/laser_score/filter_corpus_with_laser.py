import argparse


def main(args):
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


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description='Use Laser score file to output the bilingual dataset')
	parser.add_argument('--input', required=True, default='.', type=str, help='laser score file')
	parser.add_argument('--output', required=True, default='.', type=str, help='output bilingual file for NMT')
	parser.add_argument('--threshold', default=0.9, type=float)
	parser.add_argument('--lang', required=True, type=str)
	args = parser.parse_args()
	main(args)
