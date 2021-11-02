import shutil
import glob
def main():
	kohen_data_prefix = '/home/pkoehn/statmt/data/site-crawl/data'
	get_sent_file = '/home/wtan12/ParaCrawl/all-files-for-one-language.has-sent.ha'
	output_dir = '/export/b02/wtan/dataset/lett'
	with open(get_sent_file, 'r') as f:
		data = f.read()

	for line in data.split('\n'):
		folder = line.split('\t')[0]
		lett_file = f'{kohen_data_prefix}/{folder}/v2.lett.xz'
		output_dir = f'{output_dir}/{folder}'
		print(lett_file, output_dir)
		# shutil.copy(lett_file, output_dir)


if __name__ == '__main__':
    main()