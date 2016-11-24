#!/bin/bash

DIR=$(dirname $(readlink -f "$0"))
cd "$DIR"

# User settings
ALIGNED_PREFIX="$DIR/../europarl-v7"
TAGGED_PREFIX="$DIR/../txt"
SRC=fr
TARG=en

TMP_DIR="$DIR/tmp"
OUT_DIR="$DIR/out"

set -o pipefail

function f() {
	lang=$1
	echo "Processing language $lang"

	# Processing tagged files
	cat $TAGGED_PREFIX/$lang/ep*.txt | #
	sed 's/^ *<SPEAKER[^>]*> *$/<SPEAKER>/g' > "$TMP_DIR/$lang.tmp"

	patch "$TMP_DIR/$lang.tmp" "scripts/$lang.patch"
	
	if grep -c 'ENDxDOCUMENT' "$TMP_DIR/$lang.tmp"; then
		echo "ERROR: ENDxDOCUMENT appears in actual text.  We need to use that as a delimeter" > /dev/stderr
		exit 1
	fi

	# Merging
	scripts/mark_chapters -l "$lang" --aligned "$TMP_DIR/aligned.noempty.$SRC-$TARG.$lang" --tagged "$TMP_DIR/$lang.tmp" | # merge tagged and untagged
	sed '1 { /^<CHAPTER[^>]*>$/ d }; s/^<CHAPTER[^>]*>$/ENDxDOCUMENT/' | # chapter tags -> ENDxDOCUMENT tags ("</doc>" would get clobbered by tokenizer)
	scripts/normalize-punctuation.perl -l "$lang"  | # gets rid of unnecessary variance, e.g. the ~4 different unicode dashes.
	scripts/pre-tokenizer.perl -l "$lang" | # minor changes, e.g. "foo' s" becomes "foo 's"
	scripts/tokenizer.perl "$lang" | # main tokenization script
	sed 's/^ENDxDOCUMENT$/<\/doc>/' | # bak to </doc>
	scripts/remove_empty_docs.awk > "$OUT_DIR/$lang.txt"
	
	# TODO:
	# Put this all on github when I'm done so I don't lose it.
	# Have a makefile or something that wgets the appropriate corpora and does everything from scratch?
}

make -C scripts
mkdir -p "$TMP_DIR"
mkdir -p "$OUT_DIR"

echo "Removing blank lines and corresponding lines from aligned corpus"
scripts/remove_blanklines --src "$SRC" --targ "$TARG" --input-prefix "$ALIGNED_PREFIX" --output-prefix "$TMP_DIR/aligned.noempty"

f $SRC
f $TARG

