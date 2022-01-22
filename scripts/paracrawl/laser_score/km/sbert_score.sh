ROOT=/home/steven/Code/GITHUB/ParaCrawl
moses_scripts=/home/steven/Code/GITHUB/mosesdecoder/scripts
# moses helper files to preprocess the raw data
tokenizer=$moses_scripts/tokenizer/tokenizer.perl
clean=$moses_scripts/training/clean-corpus-n.perl
norm_punc=$moses_scripts/tokenizer/normalize-punctuation.perl
rem_non_print_char=$moses_scripts/tokenizer/remove-non-printing-char.perl
source $ROOT/crawl/bin/activate
# use pretrained BPE model to be consistent
BPE_TOKENS=5000
BPEROOT=/home/steven/Code/GITHUB/subword-nmt/subword_nmt
datasets=$ROOT/datasets/km/it0-filter

mkdir -p ${datasets}/filter
cp ${datasets}/train.km-en.en ${datasets}/filter/km-en.en
cp ${datasets}/translate.km-en ${datasets}/filter/translate.km-en
cp ${datasets}/train.km-en.km ${datasets}/filter/km-en.km
# score the pair

python ${ROOT}/scripts/paracrawl/laser_score/sent_sim_sbert.py \
  --lang km \
  --src-file ${datasets}/filter/km-en.km \
  --tgt-file ${datasets}/filter/km-en.en \
  --translate-file ${datasets}/filter/translate.km-en \
  --output-file ${datasets}/filter/km-en.score \
  --save-dir ${datasets}/filter --iteration 0