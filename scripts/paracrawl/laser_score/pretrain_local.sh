threshold=0.95
lr=1e-4

# Activate any environments, call your script, etc
WORK_DIR=/home/wtan12/ParaCrawl

#source /home/steven/anaconda3/etc/profile.d/conda.sh
#conda activate crawl

DATA_FOLDER=/home/steven/Code/GITHUB/ParaCrawl/data-bin/ha-en-laser-${threshold}
CHECKPOINT_FOLDER=/home/steven/Code/GITHUB/ParaCrawl/checkpoints/ha-en-laser-${threshold}

fairseq-train $DATA_FOLDER \
	--max-epoch 50 \
  --train-subset train \
  --valid-subset valid \
	-s ha -t en \
	--arch transformer_wmt_en_de \
	--share-decoder-input-output-embed \
	--optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
	--lr-scheduler inverse_sqrt --warmup-init-lr 1e-07 --warmup-updates 4000 \
	--lr ${lr} \
	--dropout 0.3 --weight-decay 0.0001 \
	--criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
	--max-tokens 1024 --update-freq 4 \
  --seed 1 \
	--log-interval 5 \
	--save-dir $CHECKPOINT_FOLDER/${lr}

