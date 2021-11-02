from LASER.source import embed
import argparse

def main():
	# use toy sentence as test first
	ha = 'Sunan yarinyar Wangari.'
	en = 'Tiv people love animals but they burn bushes to kill rats.'
	# use laser embed
	model_dir = '/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/LASER/models'
	encoder = embed.SentenceEncoder(f'{model_dir}/bilstm.93langs.2018-12-26.pt',
	                                max_sentences=10,
		                            max_tokens=10,
				                    sort_kind='quicksort',
				                    cpu=True)
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Use Laser to output a bitext datasets')
    parser.add_argument('-o', '--output', required=True, default='.', type=str, help='Output directory for the dataset')
    parser.add_argument('-i', '--input', required=True, default='.', type=str)
    args = parser.parse_args()
    main()
