from sentence_transformers import SentenceTransformer
import argparse
import sys
import torch
import numpy as np
from collections import defaultdict


def main():
    model = SentenceTransformer('all-MiniLM-L6-v2')
    sentences = ['This framework generates embeddings for each input sentence',
                 'Sentences are passed as a list of string.',
                 'The quick brown fox jumps over the lazy dog.']
    sentence_embeddings = model.encode(sentences)
    for sentence, embedding in zip(sentences, sentence_embeddings):
        print("Sentence:", sentence)
        print("Embedding:", embedding.shape)
        print("")

def get_map(filename):
    dict = defaultdict(list)
    with open(filename, 'r') as f:
        data = f.read()
    for line in data.split('\n'):
        if len(line.split('\t')) < 2:
            continue
        url, content = line.split('\t')
        dict[url].append(content)
    return dict

def document_embed(m, model):
    for k, v in m.items():
        document_embedding = model.encode(v)
        v.append(document_embedding.mean(axis=0))

def compute_match(src_m, tgt_m):
    from scipy.spatial import distance
    scores = {}
    for tgt_k in tgt_m.keys():
        tgt_embed = tgt_m[tgt_k][-1]
        max_score = -float('inf')
        similar_tgt = None
        for src_k in src_m.keys():
            src_embed = src_m[src_k][-1]
            score = distance.cosine(src_embed, tgt_embed)
            if score > max_score:
                max_score = score
                similar_src = src_k
        scores[(tgt_k, similar_src)] = max_score
    return scores




if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--src', default='.', type=str)
    parser.add_argument('--tgt', default='.', type=str)
    parser.add_argument('--threshold', default=0, type=float)
    parser.add_argument('--output-file', default='.', type=str)
    args = parser.parse_args()
    model = SentenceTransformer('all-MiniLM-L6-v2')
    # mapping from url to document
    src_map = get_map(args.src)
    tgt_map = get_map(args.tgt)
    # compute SBERT embedding for each document
    document_embed(src_map, model)
    document_embed(tgt_map, model)
    # compute cosine similarity score of document embedding
    match = compute_match(src_map, tgt_map)
    print(src_map)