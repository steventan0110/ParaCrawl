ROOT=/home/steven/Code/GITHUB/ParaCrawl
dir=/home/steven/Code/GITHUB/ParaCrawl/datasets/lett
output_dir=${ROOT}/datasets/laser_align
laser_score=${ROOT}/datasets/laser_align/en-ha.laser

# retrieve sentence of score larger than a threshold
cat $laser_score \
  | perl -ne '@a=split(/\t/); print $_ if $a[0]>0.95;' \
  > ${laser_score}.0.95


# prepare dataset for training
moses_scripts=/home/steven/Code/GITHUB/mosesdecoder/scripts
tokenizer=$moses_scripts/tokenizer/tokenizer.perl
clean=$moses_scripts/training/clean-corpus-n.perl
norm_punc=$moses_scripts/tokenizer/normalize-punctuation.perl
rem_non_print_char=$moses_scripts/tokenizer/remove-non-printing-char.perl

BPE_TOKENS=5000
BPEROOT=/home/steven/Code/GITHUB/subword-nmt/subword_nmt
ROOT=/home/steven/Code/GITHUB/ParaCrawl
source $ROOT/crawl/bin/activate

datasets=${ROOT}/datasets/laser_align
#cp ${ROOT}/datasets/raw_sent_align/dev* $datasets
#cp ${ROOT}/datasets/raw_sent_align/test* $datasets

#for threshold in 0.0 0.6 0.7 0.8 0.9 0.95; do
#  cat ${datasets}/en-ha.laser.${threshold} | cut -f2 > ${datasets}/train.ha-en-${threshold}.en
#  cat ${datasets}/en-ha.laser.${threshold} | cut -f3 > ${datasets}/train.ha-en-${threshold}.ha
#done

if true; then
  # use moses to tokenize text before BPE
  if [[ ! -e $datasets/tok ]]; then
    mkdir $datasets/tok
    for mode in train dev test; do
      for l in ha en; do
        for threshold in 0.0 0.6 0.7 0.8 0.9 0.95;  do
          if [ $mode == 'train' ]; then
            cat ${datasets}/${mode}.ha-en-${threshold}.$l | \
              perl $norm_punc $l | \
              perl $rem_non_print_char | \
              perl $tokenizer -threads 8 -a -l $l > ${datasets}/tok/${mode}.ha-en-${threshold}.$l
          else
            cat ${datasets}/${mode}.ha-en.$l | \
              perl $norm_punc $l | \
              perl $rem_non_print_char | \
              perl $tokenizer -threads 8 -a -l $l > ${datasets}/tok/${mode}.ha-en.$l
          fi
          done
      done
    done
  fi


  if [[ ! -e $datasets/bpe ]]; then
    mkdir $datasets/bpe
    for threshold in 0.0 0.6 0.7 0.8 0.9 0.95; do
      TRAIN=$datasets/bpe/train.ha-en-${threshold}
      rm -f $TRAIN
      for l in ha en; do
          cat ${datasets}/tok/train.ha-en-${threshold}.$l >> $TRAIN
      done

      BPECODE=$datasets/bpe/code-${threshold}

      echo "learn BPE code and vocab from training data"
      if [[ ! -e $BPECODE ]]; then
        python $BPEROOT/learn_joint_bpe_and_vocab.py \
          --input ${datasets}/tok/train.ha-en-${threshold}.ha ${datasets}/tok/train.ha-en-${threshold}.en -s ${BPE_TOKENS} -o ${BPECODE} \
          --write-vocabulary ${datasets}/bpe/vocab-${threshold}.ha ${datasets}/bpe/vocab-${threshold}.en --num-workers 8
      fi

      for l in ha en; do
          for mode in train dev test; do
              echo "apply_bpe.py to $mode-$threshold.$l"
              if [ $mode == 'train' ]; then
                python $BPEROOT/apply_bpe.py -c $BPECODE --vocabulary ${datasets}/bpe/vocab-${threshold}.${l} \
                --vocabulary-threshold 50 < ${datasets}/tok/${mode}.ha-en-${threshold}.$l > $datasets/bpe/${mode}.ha-en-${threshold}.$l
              else
                python $BPEROOT/apply_bpe.py -c $BPECODE --vocabulary ${datasets}/bpe/vocab-${threshold}.${l} \
                --vocabulary-threshold 50 < ${datasets}/tok/${mode}.ha-en.$l > $datasets/bpe/${mode}.ha-en-${threshold}.$l
              fi
          done
      done
    done
  fi
fi


# apply fairseq preprocess
for threshold in 0.0 0.6 0.7 0.8 0.9 0.95; do
  fairseq-preprocess \
    --source-lang ha --target-lang en \
    --joined-dictionary \
    --trainpref $datasets/bpe/train.ha-en-${threshold} \
    --validpref $datasets/bpe/dev.ha-en-${threshold} \
    --testpref $datasets/bpe/test.ha-en-${threshold} \
    --destdir $ROOT/data-bin/ha-en-laser-${threshold} \
    --workers 8
done