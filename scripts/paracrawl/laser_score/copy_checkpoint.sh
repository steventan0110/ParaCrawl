checkpoint_prefix=ha-en-simall-line
#300000 400000 500000 600000 700000
for line in 100000 200000 ; do
  tgt=/home/steven/Code/GITHUB/ParaCrawl/checkpoints/${checkpoint_prefix}-${line}/1e-4
  mkdir -p ${tgt}
  scp wtan12@login.clsp.jhu.edu:/export/b02/wtan/checkpoints/${checkpoint_prefix}-${line}/1e-4/*best.pt ${tgt}
done