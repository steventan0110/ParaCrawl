# (See qsub section for explanation on these flags.)
#$ -N translate-ps
#$ -j y -o $JOB_NAME-$JOB_ID.out
#$ -M wtan12@jhu.edu
#$ -m e

# Fill out RAM/memory (same thing) request,
# the number of GPUs you want,
# and the hostnames of the machines for special GPU models.
#$ -l ram_free=10G,mem_free=20G,cpu

# Submit to GPU queue
#$ -q g.q

dataset=/export/b02/wtan/dataset/ps-en/
CHECKPOINT_FOLDER=/export/b07/wtan12/checkpoints/ps-en-laser-5/1e-3
fairseq-interactive ${dataset}/data-bin \
  --input ${datasets}/bpe.ps \
  --path $CHECKPOINT_FOLDER/checkpoint_best.pt \
  --lenpen 1.0 \
  --remove-bpe \
  -s ps -t en \
  --beam 10