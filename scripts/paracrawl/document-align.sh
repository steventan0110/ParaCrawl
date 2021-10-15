ROOT=/home/steven/Code/GITHUB/ParaCrawl
dir=/home/steven/Code/GITHUB/ParaCrawl/datasets/toy
lett=$dir/v2.lett
language=ha
MALIGN_DOCALIGN=/home/steven/Code/GITHUB/ParaCrawl/document-aligner
source $ROOT/crawl/bin/activate

# extract lett.xz

# legacy
if [ -e $lett.gz ] && [ ! -e $lett.xz ]; then
  zcat $lett.gz | xz - > $lett.xz && rm $lett.gz
fi  

# permanent files created
txt=$dir/v2.$language.txt
english=$dir/v2.en.txt
translated=$dir/v2.$language.translated
matches=$dir/v2.$language.matches
docs=$dir/v2.en-$language.docs

touch $docs.processing

# extract foreign and english text
xzcat $lett.xz | \
    python3 $MALIGN_DOCALIGN/utils/extract_lett.py \
    --langs en,$language \
    --splitter $MALIGN_DOCALIGN/utils/split-sentences2.perl \
    --prune_type "words" \
    --prune 1000 \
    --output_prefix v2.en-$language. \
    --output_dir $dir

extracted_e=$dir/v2.en-$language.en.extracted
extracted_f=$dir/v2.en-$language.$language.extracted
extracted_translated=$dir/v2.en-$language.$language.translated

# treanslate
zcat $extracted_f.gz | xz - > $txt.xz && rm $extracted_f.gz
zcat $extracted_e.gz | xz - > $english.xz
# $LIB/translate-foreign.perl $txt.xz $language | xz - > $translated.xz
# rm $txt.xz.dedup $txt.xz.dedup.moses.log $txt.xz.dedup.translated
# paste <(xzcat $txt.xz | cut -f 1) <(xzcat $translated.xz) | gzip - > $extracted_translated.gz

# # Compute matches
# python3 $MALIGN_DOCALIGN/compute_matches.py \
#     --english $extracted_e.gz \
#     --translated $extracted_translated.gz \
#     --output_matches $matches \
#     --threshold 0.0 \
#     --batch_size 1000
# rm $extracted_e.gz
# rm $extracted_translated.gz

# # Outputting the document-aligned data in Bitextor format"
# xzcat $lett.xz | \
#   python3 $MALIGN_DOCALIGN/build_docs.py \
#   --matches $matches \
#   --threshold 0.0 | \
#   xz - > $docs.xz

# rm -f $docs.processing
# xz $matches
