#!/bin/bash

DIR=$(dirname $(readlink -f "$0"))
CORPORA_DIR="$DIR/corpora"
cd "$DIR"
SRC="fr"
REF="en"

function download() {
	if [ ! -f "$1" ]; then
		echo "Downloading $1"
		wget "$1"
	else
		echo "Using existing $1"
	fi
}

function fetch() {
	mkdir -p "$CORPORA_DIR"
	cd "$CORPORA_DIR"

	# Raw corpus
	download "http://www.statmt.org/europarl/v7/europarl.tgz"
	if [ -d "txt/$SRC" -a -d "txt/$REF" ]; then
		echo "Raw Europarl already extracted."
	else
		echo "Extracting Raw Europarl"
		# Europarl is huge. Only extract the parts we're using
		tar -xzf "europarl.tgz" "txt/$SRC" "txt/$REF"
	fi

	# Sentence-aligned corpus
	download "http://www.statmt.org/europarl/v7/$SRC-$REF.tgz"
	PREFIX="europarl-v7.$SRC-$REF"
	if [ -f "$PREFIX.$SRC" -a -f "$PREFIX.$REF" ]; then
		echo "Aligned Europarl already extracted"
	else
		echo "Extracting Aligned Europarl"
		tar -xzf "$SRC-$REF.tgz"
	fi

	# Newstest
	download "http://www.statmt.org/wmt12/dev.tgz"
	if [ -d "dev" ]; then
		echo "Newstest already extracted"
	else
		echo "Extracting Newstest"
		tar -xzf "dev.tgz"
	fi

	cd "$DIR"
}

fetch
