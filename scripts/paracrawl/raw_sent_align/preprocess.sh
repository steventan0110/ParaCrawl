moses_scripts=/home/steven/Code/GITHUB/mosesdecoder/scripts
# moses helper files to preprocess the raw data
tokenizer=$moses_scripts/tokenizer/tokenizer.perl
clean=$moses_scripts/training/clean-corpus-n.perl
norm_punc=$moses_scripts/tokenizer/normalize-punctuation.perl
rem_non_print_char=$moses_scripts/tokenizer/remove-non-printing-char.perl

BPE_TOKENS=5000
BPEROOT=/home/steven/Code/GITHUB/subword-nmt/subword_nmt
ROOT=/home/steven/Code/GITHUB/ParaCrawl
source $ROOT/crawl/bin/activate


datasets=$ROOT/datasets/raw_sent_align/
if [[ ! -e $datasets ]]; then
  cp $ROOT/datasets/lett/sent.en-ha.en $datasets
  cp $ROOT/datasets/lett/sent.en-ha.ha $datasets
  mv $datasets/sent.en-ha.en $datasets/train.ha-en.en
  mv $datasets/sent.en-ha.ha $datasets/train.ha-en.ha
fi

# use true if BPE not learned yet
if false; then
  # use moses to tokenize text before BPE
  if [[ ! -e $datasets/tok ]]; then
    mkdir $datasets/tok
    for mode in train dev test; do
      for l in ha en; do
          cat ${datasets}/${mode}.ha-en.$l | \
              perl $norm_punc $l | \
              perl $rem_non_print_char | \
              perl $tokenizer -threads 8 -a -l $l > ${datasets}/tok/${mode}.ha-en.$l
      done
    done
  fi


  if [[ ! -e $datasets/bpe ]]; then
    mkdir $datasets/bpe
    TRAIN=$datasets/bpe/train.ha-en
    rm -f $TRAIN
    for l in ha en; do
        cat ${datasets}/tok/train.ha-en.$l >> $TRAIN
    done

    BPECODE=$datasets/bpe/code
#    python $BPEROOT/learn_bpe.py -s $BPE_TOKENS < $TRAIN > $BPECODE

    echo "learn BPE code and vocab from training data"
    if [[ ! -e $BPECODE ]]; then
      python $BPEROOT/learn_joint_bpe_and_vocab.py \
        --input ${datasets}/tok/train.ha-en.ha ${datasets}/tok/train.ha-en.en -s ${BPE_TOKENS} -o ${BPECODE} \
        --write-vocabulary ${datasets}/bpe/vocab.ha ${datasets}/bpe/vocab.en --num-workers 8
    fi

    for l in ha en; do
        for mode in train dev test; do
            echo "apply_bpe.py to $mode.$l"
            python $BPEROOT/apply_bpe.py -c $BPECODE --vocabulary ${datasets}/bpe/vocab.${l} \
              --vocabulary-threshold 50 < ${datasets}/tok/${mode}.ha-en.$l > $datasets/bpe/${mode}.ha-en.$l
        done
    done
  fi
fi

# apply fairseq preprocess
fairseq-preprocess \
    --source-lang ha --target-lang en \
    --joined-dictionary \
    --trainpref $datasets/bpe/train.ha-en \
    --validpref $datasets/bpe/dev.ha-en \
    --testpref $datasets/bpe/test.ha-en \
    --destdir $ROOT/data-bin/ha-en-sent-align-raw \
    --workers 8
