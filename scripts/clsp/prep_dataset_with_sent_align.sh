ROOT=${HOME}/ParaCrawl
dir=/export/b02/wtan/dataset/lett
language=ha
MALIGN_DOCALIGN=${HOME}/ParaCrawl/document-aligner

all_sent=${dir}/sent.en-ha.all

if [ -e ${all_sent} ]; then
  rm -f ${all_sent}
fi

for sharded_dir in ${dir}/*; do
  if [[ ! -d ${sharded_dir} ]]; then
    echo ${sharded_dir} ' not a directory'
    continue
  fi
  echo "working on " ${sharded_dir}
  sent_file=${sharded_dir}/v2.en-ha.sent
  if [ ! -e ${sent_file} ]; then
    xz --decompress ${sent_file}.xz
  fi
  cat ${sent_file} >> ${all_sent}
done

sent_ha=${dir}/sent.en-ha.ha
sent_en=${dir}/sent.en-ha.en
cat ${all_sent} | cut -f3 > ${sent_en}
cat ${all_sent} | cut -f4 > ${sent_ha}

# dedup the files
cd ${ROOT}/preprocess/build/bin
./dedupe < ${sent_en} > ${sent_en}.dedup
./dedupe < ${sent_ha} > ${sent_ha}.dedup
cd $ROOT
