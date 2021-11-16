ROOT=/home/steven/Code/GITHUB/ParaCrawl
dir=/home/steven/Code/GITHUB/ParaCrawl/datasets/lett
sent_ha=${dir}/sent.en-ha.ha.dedup
sent_en=${dir}/sent.en-ha.en.dedup
output=${dir}/sent.en-ha.mine-laser

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

Process () {
  #Embed en ${sent_en} ${sent_en}.embed
  #Embed ha ${sent_ha} ${sent_ha}.embed
  Embed en $1.en $1.en.embed
  Embed ha $1.ha $1.ha.embed

  python3 ${LASER}/source/mine_bitexts.py \
      $1.en $1.ha \
      --src-lang en --trg-lang ha \
      --src-embeddings $1.en.embed \
      --trg-embeddings $1.ha.embed \
      --mode score --retrieval max --margin ratio -k 4  \
      --output $1.laser --verbose --gpu --unify
#  xz $1.laser
  rm $1.en.embed $1.ha.embed
}


# ------------------ FOR LASER MINE ----------------------#
dir=/home/steven/Code/GITHUB/ParaCrawl/datasets/laser_mine/
sent_ha=${dir}/sent.en-ha.ha.dedup
sent_en=${dir}/sent.en-ha.en.dedup
if [ ! -e ${sent_en}.filter ]; then
  cat ${sent_ha} | python $LASER_SCORING/filter-stdio.py --single-lang ha -l ha -e en --min-length 5 > ${sent_ha}.filter
  cat ${sent_en} | python $LASER_SCORING/filter-stdio.py --single-lang en -l ha -e en --min-length 5 > ${sent_en}.filter
  mv ${sent_en}.filter ${dir}/filter.en
  mv ${sent_ha}.filter ${dir}/filter.ha
fi
# mine the corpus

Process ${dir}/filter
exit

# ------------------------- FOR LASER SCORE -----------------------------#
# filter wrong language id
FILE=${dir}/sent.en-ha.dedup
FILE_FILTER=${FILE}.filter
if [! -e $FILe_FILTER ]; then
  cat $FILE | python $LASER_SCORING/filter-stdio.py --overlap 0.6 -l ha -e en --min-length 5 -i ${FILE}.index > $FILE_FILTER
fi

if [ ! -s "$FILE_FILTER.en" ] ; then
  cat $FILE_FILTER | cut -f1 > $FILE_FILTER.en
fi

if [ ! -s "$FILE_FILTER.ha" ] ; then
  cat $FILE_FILTER | cut -f2 > $FILE_FILTER.ha
fi

Process $FILE_FILTER

# split into smaller dataset and compute score for aligned data, not used for now
exit
SPLIT=500000
FILE=${dir}/laser
mkdir -p $FILE.tmp
if [ ! -s "${output}.tmp/00000.laser.xz" ] ; then
    split -a 5 -d -l $SPLIT ${dir}/sent.en-ha.en.dedup $FILE.tmp/en.
    split -a 5 -d -l $SPLIT ${dir}/sent.en-ha.ha.dedup $FILE.tmp/ha.
fi
# process one part at a time
files=$(ls $FILE.tmp | grep ^en......$)
file_array=($files)
echo "Split into ${#file_array[@]} parts."
for part in $files; do
  id="${part:3:6}"
  mv $FILE.tmp/en.$id $FILE.tmp/$id.en
  mv $FILE.tmp/ha.$id $FILE.tmp/$id.ha
  if [ ! -s "$FILE.tmp/$id.laser" ] ; then
    Process $FILE.tmp/$id
  fi
  # rm $FILE.tmp/$id.en $FILE.tmp/$id.ha
done
