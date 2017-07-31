# WMT12 Preprocessing Scripts

Preprocesses WMT12 en-fr parallel corpora, and uses the raw data to locate
document boundaries, which are then marked with \</doc> tags.

## Prerequisites
* dmd: https://dlang.org/download.html
* perl
* awk
* bash
* make

## Scripts included from other projects
* pre-tokenizer.perl : from Moses
* tokenizer.perl : from europarl tools.tgz
* normalize-punctuation.perl : from wmt12 tools

## Running
./fetch.sh will grab the corpora from the internet and extract the necessary
files to various subdirectories under ./corpora.

./run.sh can then be run immediately.

Alternately, you can download/extract them yourself and set the variables in
run.sh appropriately.


## Output

### Corpora
* europarl     : training
* newstest2010 : validation
* newstest2011 : test

### Languages
* en
* fr

It will create two files for each corpus/language pair in the "out" directory:
corpus.lang and corpus.lang.lowernum (e.g. europarl.en, europarl.en.lowernum).

The former has no recasing or replacement of words.  The latter lowercases and replaces numbers with the \<NUM> token.

Neither replace OOV words with UNK; that can be done by the model as desired.

vocab/vocab.en and vocab/vocab.fr are the vocabularies I'm using.

