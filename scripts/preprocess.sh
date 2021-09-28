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


datasets=$ROOT/datasets/ha

# use true if BPE not learned yet
if true; then
    # use moses to tokenize text before BPE
    for mode in train dev test; do
        if [ "$mode" == "train" ]; then
            # only laser file works for now
            dir=$datasets/$mode/laser
        else
            dir=$datasets/$mode
        fi
        mkdir -p $dir/tok
        for l in ha en; do
            rm $dir/tok/ha-en.$l
            cat $dir/ha-en.$l | \
                perl $norm_punc $l | \
                perl $rem_non_print_char | \
                perl $tokenizer -threads 8 -a -l $l >> $dir/tok/ha-en.$l
        done
    done

    train_dir=$datasets/train/laser/tok
    dev_dir=$datasets/dev/tok
    test_dir=$datasets/test/tok
    mkdir -p $datasets/train/laser/bpe
    mkdir -p $datasets/dev/bpe
    mkdir -p $datasets/test/bpe

    TRAIN=$datasets/train/laser/bpe/train.ha-en
    rm -f $TRAIN
    for l in ha en; do
        cat $train_dir/ha-en.$l >> $TRAIN
    done

    echo "learn BPE on training data"
    BPECODE=$datasets/train/laser/bpe/code
    python $BPEROOT/learn_bpe.py -s $BPE_TOKENS < $TRAIN > $BPECODE
    # if [ ! -e $BPECODE ]; then
    #     python $BPEROOT/learn_bpe.py -s $BPE_TOKENS < $TRAIN > $BPECODE
    # fi

    for l in ha en; do
        for mode in train dev test; do
            echo "apply_bpe.py to $mode.$l"
            if [ $mode == "train" ]; then
                python $BPEROOT/apply_bpe.py -c $BPECODE < $train_dir/ha-en.$l > $datasets/train/laser/bpe/ha-en.$l
            elif [ $mode == "dev" ]; then
                python $BPEROOT/apply_bpe.py -c $BPECODE < $dev_dir/ha-en.$l > $datasets/$mode/bpe/ha-en.$l
            else
                python $BPEROOT/apply_bpe.py -c $BPECODE < $test_dir/ha-en.$l > $datasets/$mode/bpe/ha-en.$l
            fi
        done
    done
fi 


for l in ha en; do
    rm $datasets/train.$l
    rm $datasets/dev.$l
    rm $datasets/test.$l
    cp $datasets/train/laser/bpe/ha-en.$l $datasets/train.$l
    cp $datasets/dev/bpe/ha-en.$l $datasets/dev.$l
    cp $datasets/test/bpe/ha-en.$l $datasets/test.$l
done
# apply fairseq preprocess
fairseq-preprocess \
    --source-lang ha --target-lang en \
    --joined-dictionary \
    --trainpref $datasets/train \
    --validpref $datasets/dev \
    --testpref $datasets/test \
    --destdir $ROOT/data-bin/ha-en \
    --workers 8
