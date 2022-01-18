ROOT=/home/steven/Code/GITHUB/ParaCrawl
moses_scripts=/home/steven/Code/GITHUB/mosesdecoder/scripts
# moses helper files to preprocess the raw data
tokenizer=$moses_scripts/tokenizer/tokenizer.perl
clean=$moses_scripts/training/clean-corpus-n.perl
norm_punc=$moses_scripts/tokenizer/normalize-punctuation.perl
rem_non_print_char=$moses_scripts/tokenizer/remove-non-printing-char.perl

# use pretrained BPE model to be consistent
BPE_TOKENS=5000
BPEROOT=/home/steven/Code/GITHUB/subword-nmt/subword_nmt
pretrain_dataset=$ROOT/datasets/ps_laser
BPECODE=${pretrain_dataset}/bpe/code-5
source $ROOT/crawl/bin/activate
datasets=$ROOT/datasets/ps/it0
mkdir -p $datasets
# prepare all data
cp ${ROOT}/datasets/ps_laser/dev* $datasets
cp ${ROOT}/datasets/ps_laser/test* $datasets
cat ${ROOT}/datasets/ps_laser/ps-en.laser \
  | perl -ne '@a=split(/\t/); print $_ if $a[0]>-1;' \
  | cut -f2 > ${datasets}/train.ps-en.en

cat ${ROOT}/datasets/ps_laser/ps-en.laser \
  | perl -ne '@a=split(/\t/); print $_ if $a[0]>-1;' \
  | cut -f3 > ${datasets}/train.ps-en.ps

# tokenize and BPE the dataset
for l in ps en; do
  for mode in train dev test; do
    cat ${datasets}/train.ps-en.$l | \
      perl $norm_punc $l | \
      perl $rem_non_print_char | \
      perl $tokenizer -threads 8 -a -l $l > ${datasets}/${mode}.$l.tok
  done
done

python $BPEROOT/apply_bpe.py -c $BPECODE < ${datasets}/${mode}.ps.tok > ${datasets}/${mode}.bpe.ps
python $BPEROOT/apply_bpe.py -c $BPECODE < ${datasets}/${mode}.en.tok > ${datasets}/${mode}.bpe.en


if true; then
mkdir -p ${datasets}/data-bin
# interactive is too slow, use preprocess+generate instead // have to use interactive because it keeps the order
# cp ${ROOT}/data-bin/ps-en-laser-5/dict.* ${datasets}/data-bin

#fairseq-interactive ${datasets}/data-bin \
#  --input ${datasets}/bpe.ha \
#  --path $CHECKPOINT_FOLDER/checkpoint_best.pt \
#  --lenpen 1.0 \
#  --remove-bpe \
#  -s ha -t en \
#  --beam 10 > ${datasets}/fairseq_out

# apply fairseq preprocess
fairseq-preprocess \
    --source-lang ps --target-lang en \
    --srcdict ${ROOT}/data-bin/ps-en-laser-5/dict.ps.txt \
    --tgtdict ${ROOT}/data-bin/ps-en-laser-5/dict.en.txt \
    --trainpref $datasets/train.bpe \
    --validpref $datasets/dev.bpe \
    --testpref $datasets/test.bpe\
    --destdir ${datasets}/data-bin \
    --workers 8
fi



#fairseq-generate ${datasets}/data-bin \
#    --task translation \
#    --gen-subset train \
#    --path $CHECKPOINT_FOLDER/checkpoint_best.pt \
#    --batch-size 64 \
#    --lenpen 1.0 \
#    --remove-bpe \
#    -s ha -t en \
#    --beam 10 > ${datasets}/fairseq_out
