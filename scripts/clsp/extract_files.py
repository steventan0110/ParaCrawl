import shutil
import os


def main():
	kohen_data_prefix = '/home/pkoehn/statmt/data/site-crawl/data'
	get_sent_file = '/home/wtan12/ParaCrawl/all-files-for-one-language.has-sent.ha'
	output_dir = '/export/b02/wtan/dataset/lett'
	with open(get_sent_file, 'r') as f:
		data = f.read()

	#file_to_copy = "v2.lett.xz"
	file_to_copy = "v2.en-ha.sent.xz"
	for line in data.split('\n'):
		folder = line.split('\t')[0]
		if len(folder) < 1:
			continue
		lett_file = f'{kohen_data_prefix}/{folder}/{file_to_copy}'
		folder_name = folder.replace('/', '_')
		tgt_dir_name = f'{output_dir}/{folder_name}'
		copied_file_name = f'{output_dir}/{folder_name}/{file_to_copy}'
		if os.path.exists(copied_file_name):
			continue
		if not os.path.exists(tgt_dir_name):
			os.mkdir(tgt_dir_name)
		try:
			shutil.copy(lett_file, tgt_dir_name)
		except:
			print("Issue when copying file: ", lett_file)
			continue


if __name__ == '__main__':
	main()
