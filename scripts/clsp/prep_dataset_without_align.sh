ROOT=${HOME}/ParaCrawl
dir=/export/b02/wtan/dataset/lett
language=ha
MALIGN_DOCALIGN=${HOME}/ParaCrawl/document-aligner

legacy_lett () {
  if [ -e $1.gz ] && [ ! -e $1.xz ]; then
    zcat $1.gz | xz - > $1.xz && rm $1.gz
  fi
}

extract_lett() {
  extract_dir=$2
  extracted_e=${extract_dir}/v2.en-$language.en.extracted
  extracted_f=${extract_dir}/v2.en-$language.$language.extracted
  if [ -f ${extracted_e}.gz ] || [ -f ${extracted_e} ]; then
    # already extracted
    return
  fi
  # extract foreign and english text
  xzcat $1 | \
      python3 $MALIGN_DOCALIGN/utils/extract_lett.py \
      --langs en,$language \
      --splitter $MALIGN_DOCALIGN/utils/split-sentences2.perl \
      --prune_type "words" \
      --prune 1000 \
      --output_prefix ${extract_dir}/v2.en-$language. \
      --output_dir ${extract_dir}
}

all_lett_en=${dir}/all.en.lett
all_lett_ha=${dir}/all.ha.lett

if [ -e ${all_lett_en} ]; then
  rm -f ${all_lett_en}
fi

if [ -e ${all_lett_ha} ]; then
  rm -f ${all_lett_ha}
fi

for sharded_dir in ${dir}/*; do
  if [[ ! -d ${sharded_dir} ]]; then
    echo ${sharded_dir} ' not a directory'
    continue
  fi
  lett_file_prefix=${sharded_dir}/v2.lett
  legacy_lett ${lett_file_prefix} # convert legacy gz file into xz format
  lett_file=${lett_file_prefix}.xz
  # extract related sentences from lett
  extract_lett ${lett_file} ${sharded_dir}

  extracted_e=${sharded_dir}/v2.en-$language.en.extracted
  extracted_f=${sharded_dir}/v2.en-$language.$language.extracted

  if [ ! -e ${extracted_e} ]; then
    gzip -d ${extracted_e}.gz
  fi
  if [ ! -e ${extracted_f} ]; then
    gzip -d ${extracted_f}.gz
  fi

  cat ${extracted_e} >> ${all_lett_en}
  cat ${extracted_f} >> ${all_lett_ha}
done

all_text_en=${dir}/text.en.lett
all_text_ha=${dir}/text.ha.lett
cat ${all_lett_en} | cut -f2 > ${all_text_en}
cat ${all_lett_ha} | cut -f2 > ${all_text_ha}

# dedup the files
cd ${ROOT}/preprocess/build/bin
./dedupe < ${all_text_en} > ${all_text_en}.dedup
./dedupe < ${all_text_ha} > ${all_text_ha}.dedup
cd $ROOT
