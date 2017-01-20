# WMT12 Preprocessing Scripts

Preprocesses WMT12 en-fr parallel corpora, and uses the raw data to locate
document boundaries, which are then marked with </doc> tags.

## Prerequisites
* dmd: https://dlang.org/download.html
* perl
* awk
* bash
* make

## Scripts included from other projects
pre-tokenizer.perl : from Moses
tokenizer.perl : from europarl tools.tgz
normalize-punctuation.perl : from wmt12 tools

## Running
./fetch.sh will grab the corpora from the internet and extract the necessary
files to various subdirectories under ./corpora.

./run.sh can then be run immediately.

Alternately, you can download/extract them yourself and set the variables in
run.sh appropriately.

## Miscellaneous
These scripts don't do OOV replacement or recasing; that can be done by the
model if desired.
