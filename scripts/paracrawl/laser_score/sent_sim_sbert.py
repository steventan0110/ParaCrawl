import numpy
import matplotlib.pyplot as plt

def plot_score_distribution(file):
	from collections import defaultdict
	with open(file, 'r') as f:
		data = f.read()
	score_map = defaultdict(int)
	total = 0
	for idx, lines in enumerate(data.split('\n')):
		if len(lines) < 1:
			continue
		score = lines.split('\t')[0]
		bins = numpy.arange(0, 1.5, 0.01)
		total += 1
		for i in reversed(bins):
			if float(score) >= i:
				score_map[i] += 1
				break
	print('score calculated, total number: ', total)
	import json
	with open('score_dist.json', 'w') as fp:
		json.dump(score_map, fp)
	x = []
	y = []
	for k, v in score_map.items():
		x.append(k)
		y.append(v)
	plt.scatter(x, y)
	plt.show()

def retrieve_plot():
	import json
	with open('score_dist.json', 'r') as fp:
		data = json.load(fp)
	print(data)
	x=[]
	y=[]
	for k, v in data.items():
		x.append(k)
		y.append(v/230000)
	plt.scatter(x, y)
	plt.show()


if __name__ == '__main__':
	laser_file='/home/steven/Code/GITHUB/ParaCrawl/datasets/para8/paracrawl-release8.en-ha.bifixed.dedup.laser'
	# plot_score_distribution(laser_file)
	retrieve_plot()