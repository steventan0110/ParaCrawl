WMT=/home/steven/Code/GITHUB/ParaCrawl/wmt2021
output_dir=/home/steven/Code/GITHUB/ParaCrawl/datasets/ha
dev_data=$output_dir/dev
train_data=$output_dir/train
mkdir -p $train_data
mkdir -p $dev_data
# mkdir -p $output_dir/test

echo "set up dev data"
dev_dir=$WMT/dev/xml
# only have two xml for ha as dev data
dev_file=$dev_dir/newsdev2021.ha-en.xml
if [ ! -e "$dev_data" ]; then
    python $dev_dir/extract.py $dev_file -o $dev_data/ha-en
else 
    echo "dev data already processed"
    wc -l $dev_data/*
fi

echo "set up training file"
train_dir=$WMT/paracrawl8
laser_file=$train_dir/paracrawl-release8.en-ha.bifixed.dedup.laser.filter-0.9
xml_file=$train_dir/paracrawl-release8.en-ha.bifixed.raw.tmx


if [ ! -e "$train_data/laser" ]; then
    echo "set up laser training file"
    mkdir -p $train_data/laser 
    awk -F '\t' '{print $2}' $laser_file >> $train_data/laser/ha-en.en
    awk -F '\t' '{print $3}' $laser_file >> $train_data/laser/ha-en.ha
fi

if [ ! -e "$train_data/paracrawl" ]; then
    echo "set up paracrawl training file"
fi