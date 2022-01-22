ROOT=/home/steven/Code/GITHUB/ParaCrawl
#laser_score=${ROOT}/datasets/ps/wmt20-sent.en-ps.laser-score
#laser_file=${ROOT}/datasets/ps/wmt20-sent.en-ps
output_dir=${ROOT}/datasets/ps_laser_it1_temp
mkdir -p $output_dir
# put score together with sentence pairs
# paste ${laser_score} ${laser_file} > ${output_dir}/ps-en.laser
cp ${ROOT}/datasets/pskm-dev-tools/dev-sets/wikipedia.devtest.ps-en.ps ${output_dir}/dev.ps-en.ps
cp ${ROOT}/datasets/pskm-dev-tools/dev-sets/wikipedia.devtest.ps-en.en ${output_dir}/dev.ps-en.en
cp ${ROOT}/datasets/pskm-dev-tools/dev-sets/wikipedia.test.ps-en.ps ${output_dir}/test.ps-en.ps
cp ${ROOT}/datasets/pskm-dev-tools/dev-sets/wikipedia.test.ps-en.en ${output_dir}/test.ps-en.en
output_file=${output_dir}/train.ps-en
for threshold in 2 3 5 7; do
  if [ ! -e ${output_file}-${threshold}.en ]; then
    echo "filter corpus with threshold score to certain #lines " $threshold
    python ${ROOT}/scripts/paracrawl/laser_score/filter_corpus_with_laser.py \
      --mode word \
      --lang ps --threshold ${threshold} \
      --input ${ROOT}/datasets/ps/it0/filter/ps-en.score --output ${output_file}
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
datasets=${output_dir}
# use true if BPE not learned yet
if false; then
  # use moses to tokenize text before BPE
  if [[ ! -e $datasets/tok ]]; then
    mkdir $datasets/tok
    for mode in train dev test; do
      for l in ps en; do
        for threshold in 2 3 5 7; do
          if [ $mode == 'train' ]; then
            cat ${datasets}/${mode}.ps-en-${threshold}.$l | \
              perl $norm_punc $l | \
              perl $rem_non_print_char | \
              perl $tokenizer -threads 8 -a -l $l > ${datasets}/tok/${mode}.ps-en-${threshold}.$l
          else
            cat ${datasets}/${mode}.ps-en.$l | \
              perl $norm_punc $l | \
              perl $rem_non_print_char | \
              perl $tokenizer -threads 8 -a -l $l > ${datasets}/tok/${mode}.ps-en.$l
          fi
          done
      done
    done
  fi


  if [[ ! -e $datasets/bpe ]]; then
    mkdir $datasets/bpe
    for threshold in 2 3 5 7; do
      TRAIN=$datasets/bpe/train.ps-en-${threshold}
      rm -f $TRAIN
      for l in ps en; do
          cat ${datasets}/tok/train.ps-en-${threshold}.$l >> $TRAIN
      done

      BPECODE=$datasets/bpe/code-${threshold}

      echo "learn BPE code and vocab from training data"
      if [[ ! -e $BPECODE ]]; then
        python $BPEROOT/learn_joint_bpe_and_vocab.py \
          --input ${datasets}/tok/train.ps-en-${threshold}.ps ${datasets}/tok/train.ps-en-${threshold}.en -s ${BPE_TOKENS} -o ${BPECODE} \
          --write-vocabulary ${datasets}/bpe/vocab-${threshold}.ps ${datasets}/bpe/vocab-${threshold}.en --num-workers 8
      fi

      for l in ps en; do
          for mode in train dev test; do
              echo "apply_bpe.py to $mode-$threshold.$l"
              if [ $mode == 'train' ]; then
                python $BPEROOT/apply_bpe.py -c $BPECODE --vocabulary ${datasets}/bpe/vocab-${threshold}.${l} \
                --vocabulary-threshold 50 < ${datasets}/tok/${mode}.ps-en-${threshold}.$l > $datasets/bpe/${mode}.ps-en-${threshold}.$l
              else
                python $BPEROOT/apply_bpe.py -c $BPECODE --vocabulary ${datasets}/bpe/vocab-${threshold}.${l} \
                --vocabulary-threshold 50 < ${datasets}/tok/${mode}.ps-en.$l > $datasets/bpe/${mode}.ps-en-${threshold}.$l
              fi
          done
      done
    done
  fi
fi

# apply fairseq preprocess
#for threshold in 2 3 5 7; do
#  fairseq-preprocess \
#    --source-lang ps --target-lang en \
#    --joined-dictionary \
#    --trainpref $datasets/bpe/train.ps-en-${threshold} \
#    --validpref $datasets/bpe/dev.ps-en-${threshold} \
#    --testpref $datasets/bpe/test.ps-en-${threshold} \
#    --destdir $ROOT/data-bin/ps-en-sim-${threshold} \
#    --workers 8
#done

