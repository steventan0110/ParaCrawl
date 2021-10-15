ROOT=/home/steven/Code/GITHUB/ParaCrawl
moses_scripts=/home/steven/Code/GITHUB/mosesdecoder/scripts
# moses helper files to preprocess the raw data
tokenizer=$moses_scripts/tokenizer/tokenizer.perl
clean=$moses_scripts/training/clean-corpus-n.perl
norm_punc=$moses_scripts/tokenizer/normalize-punctuation.perl
rem_non_print_char=$moses_scripts/tokenizer/remove-non-printing-char.perl

BPE_TOKENS=5000
BPEROOT=/home/steven/Code/GITHUB/subword-nmt/subword_nmt
datasets=$ROOT/datasets/ha
BPECODE=$datasets/train/laser/bpe/code
source $ROOT/crawl/bin/activate

extracted_en=${1}
extracted_ha=${2}
translate_ha=${3}
working_dir=${4}
temp_folder=${working_dir}/temp
mkdir -p $temp_folder
# use ha to generate dummy english file just to make fairseq not complaining in generation stage!
cp ${extracted_ha} ${temp_folder}/url_en
cp ${extracted_ha} ${temp_folder}/url_ha
# cut out the url part
cat ${temp_folder}/url_en | cut -f2- > ${temp_folder}/en.txt
cat ${temp_folder}/url_ha | cut -f2- > ${temp_folder}/ha.txt
# moses tokenize the file
for l in ha en; do
  cat ${temp_folder}/$l.txt | \
    perl $norm_punc $l | \
    perl $rem_non_print_char | \
    perl $tokenizer -threads 8 -a -l $l > ${temp_folder}/$l.tok
  done

# bpe the cut-out txt
python $BPEROOT/apply_bpe.py -c $BPECODE < ${temp_folder}/ha.tok > ${temp_folder}/bpe.ha
python $BPEROOT/apply_bpe.py -c $BPECODE < ${temp_folder}/en.tok > ${temp_folder}/bpe.en

# translate the input
lr=1e-4
CHECKPOINT_FOLDER=$ROOT/checkpoints/ha-en-$lr

if [ ! -e ${temp_folder}/fairseq_out ]; then
fairseq-interactive ${temp_folder}/data-bin \
  --input ${temp_folder}/bpe.ha \
  --path $CHECKPOINT_FOLDER/checkpoint_best.pt \
  --lenpen 1.0 \
  --remove-bpe \
  -s ha -t en \
  --beam 10 > ${temp_folder}/fairseq_out
fi

# cut out translated sentences and paste into output dir
cat ${temp_folder}/fairseq_out | grep ^H | cut -f3- | \
  $moses_scripts/tokenizer/detokenizer.perl > ${temp_folder}/fairseq_hyp

# put back the hypo with url
cat ${temp_folder}/url_ha | cut -f1 > ${temp_folder}/ha.url
paste ${temp_folder}/ha.url ${temp_folder}/fairseq_hyp > ${translate_ha}

