# (See qsub section for explanation on these flags.)
#$ -N translate-km
#$ -j y -o $JOB_NAME-$JOB_ID.out
#$ -M wtan12@jhu.edu
#$ -m e

# Fill out RAM/memory (same thing) request,
# the number of GPUs you want,
# and the hostnames of the machines for special GPU models.
#$ -l ram_free=10G,mem_free=20G,gpu=1,hostname=c0*|c1[123456789]

# Submit to GPU queue
#$ -q g.q

source /home/gqin2/scripts/acquire-gpu

dataset=/export/b02/wtan/dataset/km-en/
CHECKPOINT_FOLDER=/export/b07/wtan12/checkpoints/km-en-laser-5/1e-3
fairseq-interactive ${dataset}/data-bin \
  --input ${dataset}/bpe.km \
  --path $CHECKPOINT_FOLDER/checkpoint_best.pt \
  --lenpen 1.0 \
  --remove-bpe \
  -s km -t en \
  --beam 10
