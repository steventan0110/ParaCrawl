import os.path

import numpy
import matplotlib.pyplot as plt
import argparse
from pathlib import Path

import tqdm
import torch
from torch import nn
from sentence_transformers import SentenceTransformer
import pickle

def parser_args():
	parser = argparse.ArgumentParser(__doc__)
	parser.add_argument('--src-file', default=None, type=Path)
	parser.add_argument('--tgt-file', default=None, type=Path)
	parser.add_argument('--translate-file', default=None, type=Path)
	parser.add_argument('--output-file', default=None, type=Path)
	parser.add_argument('--save-dir', default='.', type=Path)
	parser.add_argument('--iteration', default='0', type=str)
	parser.add_argument('--aligned', action='store_true')
	parser.add_argument('--lang', default='ps', type=str)
	args = parser.parse_args()
	return args

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

def store_embedding_align(args):
	# we only need the generation file cuz it has src tgt and hyp
	with open(args.translate_file, 'r') as f1:
		data = f1.read()

	src_sentences, tgt_sentences, hyp_sentences = "", "", ""
	src, tgt, hyp = None, None, None
	count = 0
	for i, line in enumerate(data.split('\n')):
		if line.startswith('S-'):
			# store src
			src = line.split('\t')[1]
		elif line.startswith('T-'):
			tgt = line.split('\t')[1]
		elif line.startswith('H-'):
			hyp = line.split('\t')[2]
			# when reach hyp line, we add them to sentences
			src_sentences += src
			src_sentences += "\n"
			tgt_sentences += tgt
			tgt_sentences += "\n"
			hyp_sentences += hyp
			hyp_sentences += "\n"
			src = None
			tgt = None
			hyp = None
			count += 1
	print(f'Aligned {count} lines, start to embed them')
	model = SentenceTransformer('all-MiniLM-L6-v2')
	tgt_embeddings = model.encode(tgt_sentences.split('\n'))
	hyp_embeddings = model.encode(hyp_sentences.split('\n'))
	print(f'Using pickle protocol: {pickle.HIGHEST_PROTOCOL}')
	with open(f'{args.save_dir}/{args.lang}-embeddings-it{args.iteration}.pkl', "wb") as fOut:
		pickle.dump({'src': src_sentences,
		             'tgt': tgt_sentences,
		             'hyp': hyp_sentences,
		             'tgt_embeddings': tgt_embeddings,
		             'hyp_embeddings': hyp_embeddings,
		             }, fOut, protocol=pickle.HIGHEST_PROTOCOL)

def calculate_score_align(args):
	cos = nn.CosineSimilarity(dim=0, eps=1e-6)
	with open(f'{args.save_dir}/{args.lang}-embeddings-it{args.iteration}.pkl', "rb") as f1:
		data = pickle.load(f1)
	src_sentences = data['src'].split('\n')
	tgt_sentences = data['tgt'].split('\n')
	assert len(src_sentences) == len(tgt_sentences)
	tgt_embedding = torch.from_numpy(data['tgt_embeddings'])
	hyp_embedding = torch.from_numpy(data['hyp_embeddings'])
	out = ""
	for i in range(len(src_sentences)):
		score = cos(tgt_embedding[i, :], hyp_embedding[i, :])
		out += str(score.item())
		out += '\t'
		out += tgt_sentences[i]
		out += '\t'
		out += src_sentences[i]
		out += '\n'
	with open(f'{args.output_file}', 'w') as f4:
		f4.write(out)

def store_embedding(args):
	with open(args.tgt_file, 'r') as f1, open(args.translate_file, 'r') as f2:
		data1 = f1.read()
		data2 = f2.read()
	tgt_sentences = data1.split('\n')
	trans_sentence = data2.split('\n')
	tgt_sentences = tgt_sentences[:-1]
	trans_sentences = trans_sentence[:-1]

	model = SentenceTransformer('all-MiniLM-L6-v2')
	tgt_embeddings = model.encode(tgt_sentences)
	trans_embeddings = model.encode(trans_sentences)
	print(f'Using pickle protocol: {pickle.HIGHEST_PROTOCOL}')
	with open(f'tgt-embeddings-it{args.iteration}.pkl', "wb") as fOut:
		pickle.dump({'sentences': tgt_sentences, 'embeddings': tgt_embeddings}, fOut, protocol=pickle.HIGHEST_PROTOCOL)
	with open(f'trans-embeddings-it{args.iteration}.pkl', "wb") as fOut:
		pickle.dump({'sentences': trans_sentences, 'embeddings': trans_embeddings}, fOut,
		            protocol=pickle.HIGHEST_PROTOCOL)


def calculate_score(args):
	cos = nn.CosineSimilarity(dim=0, eps=1e-6)
	with open(f'tgt-embeddings-it{args.iteration}.pkl', "rb") as f1, \
			open(f'trans-embeddings-it{args.iteration}.pkl', 'rb') as f2:
		data1 = pickle.load(f1)
		data2 = pickle.load(f2)
		tgt_sentences = data1['sentences']
		tgt_embeddings = data1['embeddings']
		# trans_sentences = data2['sentences']
		trans_embeddings = data2['embeddings']
	output = ""
	with open(args.src_file, 'r') as f3:
		for i, src_sent in enumerate(tqdm.tqdm(f3)):
			score = cos(torch.from_numpy(tgt_embeddings[i]), torch.from_numpy(trans_embeddings[i]))
			output += str(score.item())
			output += '\t'
			output += tgt_sentences[i]
			output += '\t'
			output += src_sent.rstrip("\n")
			output += '\n'

	with open(f'{args.output_file}', 'w') as f4:
		f4.write(output)

def main(args):
	if args.src_file is None or args.tgt_file is None or args.translate_file is None:
		raise Exception('Missing Input Files')
	print(args)
	if args.aligned:
		store_embedding(args)
		calculate_score(args)
	else:
		# need to manually align the sentences from translation file first
		store_embedding_align(args)
		calculate_score_align(args)




if __name__ == '__main__':
	laser_file='/home/steven/Code/GITHUB/ParaCrawl/datasets/para8/paracrawl-release8.en-ha.bifixed.dedup.laser'
	# plot_score_distribution(laser_file)
	# retrieve_plot()
	args = parser_args()
	main(args)
