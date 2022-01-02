ROOT=/home/steven/Code/GITHUB/ParaCrawl
sent_score=${ROOT}/datasets/sent_sim/filter/ha-en.score
output_dir=${ROOT}/datasets/sent_sim_line
mkdir -p $output_dir
output_file=${output_dir}/train.ha-en
for threshold in 100000 200000 300000 400000 500000 600000 700000 800000; do
  if [ ! -e ${output_file}-${threshold}.en ]; then
    echo "filter corpus with threshold score to certain #lines " $threshold
    python filter_corpus_with_laser.py \
      --mode line \
      --lang ha --threshold ${threshold} \
      --input $sent_score --output ${output_file}
  fi
done

# prepare dataset
moses_scripts=/home/steven/Code/GITHUB/mosesdecoder/scripts
tokenizer=$moses_scripts/tokenizer/tokenizer.perl
clean=$moses_scripts/training/clean-corpus-n.perl
norm_punc=$moses_scripts/tokenizer/normalize-punctuation.perl
rem_non_print_char=$moses_scripts/tokenizer/remove-non-printing-char.perl

BPE_TOKENS=5000
BPEROOT=/home/steven/Code/GITHUB/subword-nmt/subword_nmt
ROOT=/home/steven/Code/GITHUB/ParaCrawl
source $ROOT/crawl/bin/activate


datasets=${ROOT}/datasets/sent_sim_line
cp ${ROOT}/datasets/raw_sent_align/dev* $datasets
cp ${ROOT}/datasets/raw_sent_align/test* $datasets
# use true if BPE not learned yet
if true; then
  # use moses to tokenize text before BPE
  if [[ ! -e $datasets/tok ]]; then
    mkdir $datasets/tok
    for mode in train dev test; do
      for l in ha en; do
        for threshold in 100000 200000 300000 400000 500000 600000 700000 800000; do
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
    for threshold in 100000 200000 300000 400000 500000 600000 700000 800000; do
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
for threshold in 100000 200000 300000 400000 500000 600000 700000 800000; do
  fairseq-preprocess \
    --source-lang ha --target-lang en \
    --joined-dictionary \
    --trainpref $datasets/bpe/train.ha-en-${threshold} \
    --validpref $datasets/bpe/dev.ha-en-${threshold} \
    --testpref $datasets/bpe/test.ha-en-${threshold} \
    --destdir $ROOT/data-bin/ha-en-sent-sim-line-${threshold} \
    --workers 8
done

