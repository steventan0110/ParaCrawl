#!/usr/bin/env bash

threshold=0.75
# (See qsub section for explanation on these flags.)
#$ -N pretrain-ha-en-lasers-${threshold}
#$ -j y -o $JOB_NAME-$JOB_ID.out
#$ -M wtan12@jhu.edu
#$ -m e

# Fill out RAM/memory (same thing) request,
# the number of GPUs you want,
# and the hostnames of the machines for special GPU models.
#$ -l ram_free=10G,mem_free=20G,gpu=1,hostname=c0*|c1[123456789]

# Submit to GPU queue
#$ -q g.q

# Assign a free-GPU to your program (make sure -n matches the requested number of GPUs above)
source /home/gqin2/scripts/acquire-gpu
# or, less safely:
# export CUDA_VISIBLE_DEVICES=$(free-gpu -n 1)

# Activate any environments, call your script, etc
WORK_DIR=/home/wtan12/ParaCrawl

conda activate crawl

DATA_FOLDER=/export/b02/wtan/data-bin/ha-en-sent-align-laser-${threshold}
CHECKPOINT_FOLDER=/export/b02/wtan/checkpoints/ha-en-sent-align-laser-${threshold}


fairseq-train $DATA_FOLDER \
	--max-epoch 50 \
  --train-subset train \
  --valid-subset valid \
	-s ha -t en \
	--arch transformer_wmt_en_de \
	--share-decoder-input-output-embed \
	--optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
	--lr-scheduler inverse_sqrt --warmup-init-lr 1e-07 --warmup-updates 4000 \
	--lr 1e-4 \
	--dropout 0.3 --weight-decay 0.0001 \
	--criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
	--max-tokens 1024 --update-freq 4 \
  --seed 1 \
	--log-interval 5 \
	--save-dir $CHECKPOINT_FOLDER
																             
