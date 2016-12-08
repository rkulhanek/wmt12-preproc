#!/bin/bash

DIR=$(dirname $(readlink -f "$0"))
cd "$DIR"

# User settings
CORPORA_DIR="$DIR/corpora"
TMP_DIR="$DIR/tmp"
OUT_DIR="$DIR/out"

ALIGNED_PREFIX="$CORPORA_DIR/europarl-v7"
TAGGED_PREFIX="$CORPORA_DIR/txt"
DEV_DIR="$CORPORA_DIR/dev"

VALID_PREFIX="newstest2010"
TEST_PREFIX="newstest2011"
SRC=fr
REF=en
# </User settings>

set -o pipefail

function parse_europarl() {
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
	scripts/mark_chapters -l "$lang" --aligned "$TMP_DIR/aligned.noempty.$SRC-$REF.$lang" --tagged "$TMP_DIR/$lang.tmp" | # merge tagged and untagged
	sed '1 { /^<CHAPTER[^>]*>$/ d }; s/^<CHAPTER[^>]*>$/ENDxDOCUMENT/' | # chapter tags -> ENDxDOCUMENT tags ("</doc>" would get clobbered by tokenizer)
	sed '/^<EOF>$/ d' | # remove <EOF> tag from end
	scripts/normalize-punctuation.perl -l "$lang"  | # gets rid of unnecessary variance, e.g. the ~4 different unicode dashes.
	scripts/pre-tokenizer.perl -l "$lang" | # minor changes, e.g. "foo' s" becomes "foo 's"
	scripts/tokenizer.perl -l "$lang" | # main tokenization script
	sed 's/^ENDxDOCUMENT$/<\/doc>/' | # bak to </doc>
	scripts/remove_empty_docs.awk > "$OUT_DIR/europarl.$lang"
	
	# TODO:
	# Put this all on github when I'm done so I don't lose it.
	# Have a makefile or something that wgets the appropriate corpora and does everything from scratch?
}

function parse_newstest() {
	prefix="$1"
	lang="$2"
	src_ref="$3"

	in="$DEV_DIR/$prefix-$src_ref.$lang.sgm"
	out="$OUT_DIR/$prefix.$lang"

	sed -rn '
		/^<\/doc/ {p}
		/^<seg[^>]*>(.*)<\/seg>/ {
			s/<seg[^>]*>(.*)<\/seg>/\1/
			p
		}
	' < "$in" | # convert from sgm to "sentence per line with </doc> tags"
	scripts/normalize-punctuation.perl -l "$lang"  | # gets rid of unnecessary variance, e.g. the ~4 different unicode dashes.
	scripts/pre-tokenizer.perl -l "$lang" | # minor changes, e.g. "foo' s" becomes "foo 's"
	scripts/tokenizer.perl "$lang" > "$out" # main tokenization script
}

function verify() {
	IFS=$'\n'
	echo "Sanity-checking line counts"
	cd "$OUT_DIR"

	WC=$(wc -l * | grep -v 'total$')
	CORPORA=$(echo "$WC" | sed -r 's/^ *[0-9]+ +(.*)\.[a-z]+$/\1/' | sort -u)
	echo "$WC"

	for i in $CORPORA; do
		src_lines=$(wc -l $i.$SRC | grep -v 'total$' | awk '{print $1}')
		ref_lines=$(wc -l $i.$REF | grep -v 'total$' | awk '{print $1}')

		if [ $src_lines != $ref_lines ]; then
			echo "ERROR: Line counts don't match for $i" > /dev/stderr
		fi
	done
	echo "All line counts match" > /dev/stderr

	cd "$DIR"
}

make -C scripts
mkdir -p "$TMP_DIR"
mkdir -p "$OUT_DIR"

echo "Removing blank lines and corresponding lines from aligned corpus"
scripts/remove_blanklines --src "$SRC" --targ "$REF" --input-prefix "$ALIGNED_PREFIX" --output-prefix "$TMP_DIR/aligned.noempty"

parse_europarl $SRC
parse_europarl $REF
parse_newstest "$VALID_PREFIX" "$SRC" src
parse_newstest "$VALID_PREFIX" "$REF" src
parse_newstest "$TEST_PREFIX" "$SRC" src
parse_newstest "$TEST_PREFIX" "$REF" src
verify

# Lowercase and map numbers to <NUM>
for i in $(find $OUT_DIR -name "*.$SRC" -o -name "*.$REF"); do
	echo "Lowercase and <NUM> : "$i
	scripts/lowernum < "$i" > "$i.lowernum"
done

