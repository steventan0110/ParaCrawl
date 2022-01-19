#!/usr/bin/env bash

# (See qsub section for explanation on these flags.)
#$ -N pretrain-ps-sim-2
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

DATA_FOLDER=/export/b02/wtan/data-bin/ps-en-sim-2
CHECKPOINT_FOLDER=/export/b07/wtan12/checkpoints/ps-en-sim-2/1e-3

fairseq-train $DATA_FOLDER \
  --source-lang ps --target-lang en \
  --arch transformer --share-all-embeddings \
  --encoder-layers 5 --decoder-layers 5 \
  --encoder-embed-dim 512 --decoder-embed-dim 512 \
  --encoder-ffn-embed-dim 2048 --decoder-ffn-embed-dim 2048 \
  --encoder-attention-heads 2 --decoder-attention-heads 2 \
  --encoder-normalize-before --decoder-normalize-before \
  --dropout 0.4 --attention-dropout 0.2 --relu-dropout 0.2 \
  --weight-decay 0.0001 \
  --label-smoothing 0.2 --criterion label_smoothed_cross_entropy \
  --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0 \
  --lr-scheduler inverse_sqrt --warmup-updates 4000 --warmup-init-lr 1e-7 \
  --lr 1e-3 --min-lr 1e-9 \
  --max-tokens 4000 \
  --update-freq 4 \
  --save-dir $CHECKPOINT_FOLDER \
  --max-epoch 100 --save-interval 10


