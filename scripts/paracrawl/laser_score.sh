ROOT=/home/steven/Code/GITHUB/ParaCrawl
dir=/home/steven/Code/GITHUB/ParaCrawl/datasets/lett
sent_ha=${dir}/sent.en-ha.ha.dedup
sent_en=${dir}/sent.en-ha.en.dedup
output=${dir}/sent.en-ha.laser

export LASER=/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/LASER
export LASER_SCORING=/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/laser-scoring
model_dir="${LASER}/models"
encoder="${model_dir}/bilstm.93langs.2018-12-26.pt"
bpe_codes="${model_dir}/93langs.fcodes"

conda activate crawl

Embed () {
  ll=$1
  txt=$2
  embed=$3

  if [ ! -s ${embed} ] ; then
    cat ${txt} | python3 ${LASER}/source/embed.py \
      --encoder ${encoder} \
      --token-lang ${ll} \
      --bpe-codes ${bpe_codes} \
      --output ${embed} \
      --verbose
   fi
}

Embed en ${sent_en} ${sent_en}.embed
Embed ha ${sent_ha} ${sent_ha}.embed


python3 ${LASER}/source/mine_bitexts.py \
    ${sent_en} ${sent_ha} \
    --src-lang en --trg-lang ha \
    --src-embeddings ${sent_en}.embed \
    --trg-embeddings ${sent_ha}.embed \
    --mode score --retrieval max --margin ratio -k 4  \
    --output ${output} --verbose --gpu --unify

# python $ROOT/scripts/paracrawl/laser_score.py --file1 ${sent_en} --file2 ${sent_ha} -o ${output}

