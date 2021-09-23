#!/usr/bin/env bash

# (See qsub section for explanation on these flags.)
#$ -N dual-nll-training-zh
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
WORK_DIR=/home/wtan12/NMTModelAttack

conda activate model-attack

DATA_FOLDER=/export/b02/wtan/data-bin/zh-en
PRETRAIN_MODEL=/export/b02/wtan/checkpoints/dual-mrt/zhen_checkpoint.pt
CHECKPOINT_FOLDER=/export/b02/wtan/checkpoints/dual-nll/zh
AUX_MODEL=/export/b02/wtan/checkpoints/dual-mrt/enzh_checkpoint.pt
AUX_MODEL_SAVE=/export/b02/wtan/checkpoints/dual-nll/zh-aux
COMET_PATH=/home/wtan12/.cache/torch/unbabel_comet/wmt-large-da-estimator-1719/_ckpt_epoch_1.ckpt

SRC_FILE=/export/b02/wtan/dataset/otf-comet/nouse
TGT_FILE=/export/b02/wtan/dataset/otf-comet/nouse

fairseq-train $DATA_FOLDER \
	--max-epoch 30 \
	-s zh -t en \
	--train-subset valid \
	--valid-subset valid1 \
	--share-decoder-input-output-embed \
	--encoder-embed-dim 512 \
	--arch transformer_wmt_en_de \
	--dual-training \
	--auxillary-model-path $AUX_MODEL \
	--auxillary-model-save-dir $AUX_MODEL_SAVE \
	--optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
	--lr-scheduler inverse_sqrt --warmup-init-lr 1e-04 --warmup-updates 1000 \
	--lr 0.00001 --min-lr 1e-06 \
	--dropout 0.3 --weight-decay 0.0001 \
	--beta 0.8 \
	--criterion dual_nll --label-smoothing 0.1 \
	--max-tokens 1024 --update-freq 1 \
	--on-the-fly-train --adv-percent 30 \
	--src-file $SRC_FILE --tgt-file $TGT_FILE \
	--seed 2 \
	--restore-file $PRETRAIN_MODEL \
	--reset-optimizer \
	--reset-dataloader \
	--save-dir $CHECKPOINT_FOLDER
done
																             
