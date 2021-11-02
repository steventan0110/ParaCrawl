ROOT=/home/steven/Code/GITHUB/ParaCrawl
dir=/home/steven/Code/GITHUB/ParaCrawl/datasets/toy
lett=$dir/v2.lett
language=ha
MALIGN_DOCALIGN=/home/steven/Code/GITHUB/ParaCrawl/document-aligner
LIB=/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/perl
export LASER=/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/LASER
export LASER_SCORING=/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/laser-scoring
model_dir="${LASER}/models"
encoder="${model_dir}/bilstm.93langs.2018-12-26.pt"
bpe_codes="${model_dir}/93langs.fcodes"


en_file=$dir/v2.en.txt
ha_file=$dir/v2.ha.txt

cut -f2 $en_file > $dir/en.temp.txt
cut -f2 $ha_file > $dir/ha.temp.txt

en_embed=$dir/en.temp.embed
cat $dir/en.temp.txt | python3 ${LASER}/source/embed.py \
      --encoder ${encoder} \
      --token-lang en \
      --bpe-codes ${bpe_codes} \
      --output ${en_embed} \
      --verbose