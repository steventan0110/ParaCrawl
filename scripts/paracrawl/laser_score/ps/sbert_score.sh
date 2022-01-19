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
datasets=$ROOT/datasets/ps/it0

if [ ! -e ${datasets}/sent-sim.en ]; then
  # cat ${datasets}/sent-sim-filter.out | grep ^H | cut -f3- | $moses_scripts/tokenizer/detokenizer.perl > ${datasets}/sent-sim-filter.en
  cat ${datasets}/sent-sim.out | grep ^H | cut -f3- | $moses_scripts/tokenizer/detokenizer.perl > ${datasets}/sent-sim.en
fi

mkdir -p ${datasets}/filter
cp ${datasets}/train.ps-en.en ${datasets}/filter/ps-en.en
cp ${datasets}/sent-sim.en ${datasets}/filter/translate.en
cp ${datasets}/train.ps-en.ps ${datasets}/filter/ps-en.ps
# score the pair

echo "python sent_sim_sbert.py \
  --src-file ${datasets}/filter/ps-en.ps \
  --tgt-file ${datasets}/filter/ps-en.en \
  --translate-file ${datasets}/filter/translate.en \
  --output-file ${datasets}/filter/ps-en.score"