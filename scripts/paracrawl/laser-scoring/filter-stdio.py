import argparse
import sys
import re
import fasttext

FOREIGN_LANG = ''
SIMILARITY_THRESHOLD = 0
MIN_LENGTH = 1
MAX_LENGTH = 1000
SPACE_NORMALIZER = re.compile("\s+")
LID_MODEL_PATH = '/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/laser-scoring/lid.176.bin'
model = fasttext.load_model(LID_MODEL_PATH)
EN = 'en'

def parse_args():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('-l', '--language', help="Foreign language iso id")
    parser.add_argument('-o', '--overlap', help="Filter against overlap (recommended: 0.6)")
    parser.add_argument('-e', '--english', help="English language iso id")
    parser.add_argument('-i', '--index', help="Index file indicating drops")
    parser.add_argument('-m', '--min-length', help="Minimum number of tokens per segment")
    parser.add_argument('-x', '--max-length', help="Maximum number of tokens per segment")
    parser.add_argument('--single-lang', default=None, type=str, help="Only filter for a single file")
    args = parser.parse_args()
    return args

def acceptable_overlap(s1, s2):
    s1_list = s1.split()
    s2_list = s2.split()
    return (len(set(s1_list) and set(s2_list)) / float(len(set(s1_list) | set(s2_list)))) < 0.6

def correct_lang_id(s1, s2, foreign_lang):
    # return model.predict(s1)[0][0] == "__label__" + EN and model.predict(s2)[0][0] == "__label__" + foreign_lang
    # TODO: change this to only eliminate eng id because we are dealing with low resource data
    return model.predict(s1)[0][0] == "__label__" + EN and model.predict(s2)[0][0] != "__label__" + EN

def correct_lang_id_single(s1, foreign_lang):
    if foreign_lang == 'en':
        return model.predict(s1)[0][0] == "__label__" + EN
    else:
        return model.predict(s1)[0][0] != "__label__" + EN

def main():
    args = parse_args()
    if args.english:
      EN=args.english
    if args.overlap:
      SIMILARITY_THRESHOLD=float(args.overlap)
    if args.max_length:
      MAX_LENGTH=int(args.max_length)
    if args.min_length:
      MIN_LENGTH=int(args.min_length)
    if args.index:
      fh_index = open(args.index, mode='w')
    if args.single_lang is not None:
        filter_lang = args.single_lang
        for raw_line in sys.stdin:
            text = SPACE_NORMALIZER.sub(" ", raw_line.strip())
            if (raw_line.strip() != "" and
                (args.min_length is None or (len(text.split()) >= MIN_LENGTH)) and
                (args.max_length is None or (len(text.split()) <= MAX_LENGTH)) and
                (args.language   is None or correct_lang_id_single(text, filter_lang))):
                print(raw_line, end = '')
                if args.index:
                    fh_index.write("1\n")
            elif args.index:
                fh_index.write("0\n")

    else:
        for raw_line in sys.stdin:
            line = raw_line.split('\t')
            e = SPACE_NORMALIZER.sub(" ", line[0].strip())
            f = SPACE_NORMALIZER.sub(" ", line[1].strip())
            if (line[0].strip() != "" and
                line[1].strip() != "" and
                (args.min_length is None or (len(e.split()) >= MIN_LENGTH and len(f.split()) >= MIN_LENGTH)) and
                (args.max_length is None or (len(e.split()) <= MAX_LENGTH and len(f.split()) <= MAX_LENGTH)) and
                (args.overlap    is None or acceptable_overlap(e, f)) and
                (args.language   is None or correct_lang_id(e, f, args.language))):
                print(raw_line, end = '')
                if args.index:
                    fh_index.write("1\n")
            elif args.index:
                fh_index.write("0\n")

if __name__== "__main__":
        main()
