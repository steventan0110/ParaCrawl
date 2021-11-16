ROOT=/home/steven/Code/GITHUB/ParaCrawl
dir=/home/steven/Code/GITHUB/ParaCrawl/datasets/lett
language=ha
MALIGN_DOCALIGN=/home/steven/Code/GITHUB/ParaCrawl/document-aligner
LIB=/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/perl
export LASER=/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/LASER
export LASER_SCORING=/home/steven/Code/GITHUB/ParaCrawl/scripts/paracrawl/laser-scoring
model_dir="${LASER}/models"
encoder="${model_dir}/bilstm.93langs.2018-12-26.pt"
bpe_codes="${model_dir}/93langs.fcodes"


all_sent=${dir}/sent.en-ha.all

#if [ -e ${all_sent} ]; then
#  rm -f ${all_sent}
#fi
#
#for sharded_dir in ${dir}/*; do
#  if [[ ! -d ${sharded_dir} ]]; then
#    echo ${sharded_dir} ' not a directory'
#    continue
#  fi
#  lett_file_prefix=${sharded_dir}/v2.lett
#  sent_file=${sharded_dir}/v2.en-ha.sent
#  if [ ! -e ${sent_file} ]; then
#    xz --decompress ${sent_file}.xz
#  fi
#
#  cat ${sent_file} >> ${all_sent}
#done

sent_ha=${dir}/sent.en-ha.ha
sent_en=${dir}/sent.en-ha.en
#cat ${all_sent} | cut -f3 > ${sent_en}
#cat ${all_sent} | cut -f4 > ${sent_ha}

sent_ha_en=${dir}/sent.en-ha
#paste ${sent_en} ${sent_ha} > ${sent_ha_en}

# dedup on each language individually
laser_mine=/home/steven/Code/GITHUB/ParaCrawl/datasets/laser_mine
mkdir -p $laser_mine
sent_ha=${laser_mine}/sent.en-ha.ha
sent_en=${laser_mine}/sent.en-ha.en
cat ${all_sent} | cut -f3 > ${sent_en}
cat ${all_sent} | cut -f4 > ${sent_ha}
cd /home/steven/Code/GITHUB/preprocess/build/bin
./dedupe < ${sent_en} > ${sent_en}.dedup
./dedupe < ${sent_ha} > ${sent_ha}.dedup


# dedup the src-tgt together and use laser score instead of laser mine
cd /home/steven/Code/GITHUB/preprocess/build/bin
# ./dedupe < ${sent_ha_en} > ${sent_ha_en}.dedup
#./dedupe < ${sent_en} > ${sent_en}.dedup
#./dedupe < ${sent_ha} > ${sent_ha}.dedup
#cd $ROOT

#cat ${sent_ha_en}.dedup | cut -f2 > ${sent_ha}.dedup
#cat ${sent_ha_en}.dedup | cut -f1 > ${sent_en}.dedup