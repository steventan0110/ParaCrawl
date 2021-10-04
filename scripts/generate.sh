moses_scripts=/home/steven/Code/GITHUB/mosesdecoder/scripts
ROOT=/home/steven/Code/GITHUB/ParaCrawl
lr=1e-4
output_dir=$ROOT/output/ha-en-$lr
mkdir -p $output_dir
source $ROOT/crawl/bin/activate

CHECKPOINT_FOLDER=$ROOT/checkpoints/ha-en-$lr
DATA_FOLDER=$ROOT/data-bin/ha-en
filename="transformer"
if true; then
    fairseq-generate $DATA_FOLDER \
        --task translation \
        --gen-subset test \
        --path $CHECKPOINT_FOLDER/checkpoint_best.pt \
        --batch-size 64 \
        --lenpen 1.0 \
        --remove-bpe \
        -s ha -t en \
        --beam 10 >> $output_dir/$filename.out	
fi

# detokenize and score	
cat $output_dir/$filename.out | grep ^H | cut -f3- | $moses_scripts/tokenizer/detokenizer.perl >> $output_dir/$filename.out.detok
cat $output_dir/$filename.out | grep ^T | cut -f2- | $moses_scripts/tokenizer/detokenizer.perl >> $output_dir/$filename.ref.detok

# score with sacrebleu
echo "The BLEU score is: "
sacrebleu $output_dir/$filename.ref.detok -i $output_dir/$filename.out.detok -m bleu -b -w 4

