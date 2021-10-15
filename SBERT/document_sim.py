from sentence_transformers import SentenceTransformer
import argparse
import sys
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


if __name__ == '__main__':
    main()