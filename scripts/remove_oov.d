/* Replace OOV words with <UNK> */

import std.stdio, std.algorithm, std.array, std.string, std.getopt;

void main(string[] argv) {
	string vocab_fname;//each line can be in either either "word" or "word count" format.

	auto opt = getopt(argv,
		std.getopt.config.required, "vocab", &vocab_fname
	);

	if (opt.helpWanted) {
		defaultGetoptPrinter("", opt.options);
		return;
	}

	ulong[string] vocab;
	foreach (line; File(vocab_fname).byLineCopy) {
		vocab[line.split[0]] = vocab.length;
	}
	stderr.writef("Vocab: %s\n", vocab.length);

	string toUnk(string word) {
		if (word in vocab) return word;
		return "<UNK>";
	}

	foreach (line; stdin.byLineCopy) {
		line.split
			.map!toUnk
			.join(' ')
			.writeln;
	}
}

