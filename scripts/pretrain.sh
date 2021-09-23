ROOT=/home/steven/Code/GITHUB/ParaCrawl
source $ROOT/crawl/bin/activate

CHECKPOINT_FOLDER=$ROOT/checkpoints/ha-en
DATA_FOLDER=$ROOT/data-bin/ha-en

fairseq-train $DATA_FOLDER \
	--max-epoch 50 \
    --train-subset train \
    --valid-subset valid \
	-s ha -t en \
	--arch transformer_wmt_en_de \
	--optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
	--lr-scheduler inverse_sqrt --warmup-init-lr 1e-07 --warmup-updates 1000 \
	--lr 5e-4 \
	--dropout 0.3 --weight-decay 0.0001 \
	--criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
	--max-tokens 1024 --update-freq 4 \
    --max-update 4000 \
    --seed 1 \
	--log-interval 5 \
	--save-dir $CHECKPOINT_FOLDER													             
