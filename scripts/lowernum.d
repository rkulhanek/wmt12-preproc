/* IMPORTANT: The input should be passed through this *before* OOV replacement.  It's entirely possible that 
   this will produce some <NUM>-<NUM>-<NUM>...-<NUM> sequence that isn't in the vocabulary, and thus should be replaced by <UNK>
   */
import std.stdio, std.regex, std.format, std.algorithm, std.array, std.string;

auto numbers(string word) {
	const static auto NUMBER_BLOCK = `((\d+[,.])*\d+)`; // e.g. "42", "42.42", "42,42", "42,42,42"
	const static auto NON_NEGATIVE = format("([,.]?%s+[.,]?)", NUMBER_BLOCK);
	const static auto NUMBER = format("(-?%s)", NON_NEGATIVE);

	/* Patterns that match this get replaced by e.g. <NUM>-<NUM> or <NUM>-<NUM>-<NUM>
	   I allow the dashes to be multiple--dashes.
	   I also allow trailing dashes, since every time I saw that in the corpus, it was a typo for the normal range. */
	//auto DELIM=`(-+)`;
	//auto NUMBER_RANGE=ctRegex!format("^(<NUM>%s)*(%s%s)+%s%s?$", DELIM, NON_NEGATIVE, DELIM, NON_NEGATIVE, DELIM);

	string toNum(string s) {
		return s.replaceFirst(
			ctRegex!(format("^%s$", NUMBER)),
			"<NUM>");
	}
	word = toNum(word);

	auto parts = word.splitter(ctRegex!`-+`);

	auto f(string s) {
		const static auto re = format("^%s?$", NON_NEGATIVE);
		return s.matchFirst(ctRegex!re);
	};

	if (parts.all!f) {
		word = parts.map!toNum.array.join('-');
	}
/*
	while (word.matchFirst(NUMBER_RANGE)) {
		word = word.replaceFirst(ctRegex!NON_NEGATIVE, "<NUM>");
	}
	if (word.matchFirst(ctRegex!format(`^(<NUM>%s)*%s%s?$`, DELIM, NON_NEGATIVE, DELIM))) {
		word = word.replaceFirst(ctRegex!format(`%s%s?`), "<NUM>");
	}*/
	return word;
}

void main() {
	foreach (line; stdin.byLineCopy) {
		line.split
			.map!toLower
			.map!numbers
			.join(' ')
			.writeln;
	}
}

