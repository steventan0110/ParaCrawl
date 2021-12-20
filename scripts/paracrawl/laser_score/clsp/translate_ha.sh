# (See qsub section for explanation on these flags.)
#$ -N translate-ha
#$ -j y -o $JOB_NAME-$JOB_ID.out
#$ -M wtan12@jhu.edu
#$ -m e

# Fill out RAM/memory (same thing) request,
# the number of GPUs you want,
# and the hostnames of the machines for special GPU models.
#$ -l ram_free=10G,mem_free=20G,cpu

# Submit to GPU queue
#$ -q g.q

dataset=/export/b02/wtan/dataset/sent_sim/
CHECKPOINT_FOLDER=/export/b02/wtan/checkpoints/ha-en-1e-4
fairseq-interactive ${dataset}/data-bin \
  --input ${datasets}/bpe.ha \
  --path $CHECKPOINT_FOLDER/checkpoint_best.pt \
  --lenpen 1.0 \
  --cpu \
  --remove-bpe \
  -s ha -t en \
  --beam 10