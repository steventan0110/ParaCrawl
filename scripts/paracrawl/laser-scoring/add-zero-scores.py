import argparse
import sys

def parse_args():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('-o', '--original', required=True, help="Original file")
    parser.add_argument('-s', '--scored', required=True, help="Scored file")
    parser.add_argument('-i', '--index', required=True, help="Index file indicating drops")
    args = parser.parse_args()
    return args

def main():
    args = parse_args()
    fh_index    = open(args.index,    mode='r')
    fh_original = open(args.original, mode='r')
    fh_scored   = open(args.scored,   mode='r')
    while True:
        index_line = fh_index.readline()
        if not index_line:
            break
        original_line = fh_original.readline()
        if int(index_line) == 1:
            scored_line = fh_scored.readline()
            print(scored_line, end='')
        else:
            print("0\t" + original_line, end='')

if __name__== "__main__":
        main()
