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
pretrain_dataset=$ROOT/datasets/ha
BPECODE=${pretrain_dataset}/train/laser/bpe/code
datasets=$ROOT/datasets/sent_sim

if [ ! -e ${datasets}/sent-sim.en ]; then
  cat ${datasets}/sent-sim-filter.out | grep ^H | cut -f3- | $moses_scripts/tokenizer/detokenizer.perl > ${datasets}/sent-sim-filter.en
  cat ${datasets}/sent-sim.out | grep ^H | cut -f3- | $moses_scripts/tokenizer/detokenizer.perl > ${datasets}/sent-sim.en
fi

mkdir -p ${datasets}/filter
#cp ${datasets}/train.ha-en.en ${datasets}/filter/ha-en.en
#cp ${datasets}/sent-sim-filter.en ${datasets}/filter/translate.en
#cp ${datasets}/train.ha-en.ha ${datasets}/filter/ha-en.ha
# score the pair

echo "python sent_sim_sbert.py \
  --src-file ${datasets}/filter/ha-en.ha \
  --tgt-file ${datasets}/filter/ha-en.en \
  --translate-file ${datasets}/filter/translate.en
  --output-file ${datasets}/filter/ha-en.score"