#!/usr/bin/dmd -run
import std.stdio, std.string, std.concurrency, std.regex, std.algorithm, std.getopt;

version = french;
string language = "fr";

/*
Assumptions:

Let A be the content of the en/txt/ep*.txt files, with all tags removed/ignored.
Let B be europarl-v7.whatever.en

Treat each as a sequence of words.
Assume that B contains all words that A does, plus extras.

Scan through A and B.
Mark words in B as they're identified in A.  If A is predicting a word that isn't in B,
scan forward in B until we find it.

Maybe instead of words, we should be using lines, where line breaks are added to A after each period.

While scanning through B, keep a running identifier of file/chapter


NOTE:
This is *europarl*.  The formatting is way too inconsistent across the
different versions to completely automate.  The generally effective approach is
to concatenate all the ep*.txt files into all.txt, then run this program until
it crashes, then look at the failing lines in corpus_no_docs.txt and
corpus_with_docs.txt to find out what got split differently across them, and
make the necessary changes to all.txt by hand.  It tends to make it about 50k to 100k
lines further each time.

*/

auto lineno_nodocs = 1;
auto lineno_docs = 1;

const bool DEBUG_LEVEL = 0;

auto splitlines(string fname, bool mark_newlines) {
	//Splitting on - makes the French corpus a pain, since a lot of lines start with "   -" (Actually 0xc2a0 0xc2a0 0x20 0x2d)
	const string split_on = 
		("fr" == language) ? `([.!?][\])'"’”]*) +` :
		("en" == language) ?  `([\-.!?][\])'"’”]*) +` :
		"";

	return new Generator!string({
		foreach (string s; lines(File(fname))) {
			if (s.matchAll(regex("<.*>")) && !s.strip().matchFirst(regex(`<[^>]*>$`))) {
				stderr.writef("%s, %s: Removing inline tag from line: \"%s\"\n", lineno_nodocs, lineno_docs, s);
				s = s.replaceAll(regex(`<[^>]*>`), "");
			}
				
			if ("en" == language) {
				foreach (t; s.replaceAll(regex(split_on), "$1\n") /*.strip()*/ .splitter("\n")) {
					//t = t./*strip().*/replaceAll(regex(` +`), " ").strip();
					//if (t.length) yield(t);
					yield(t);
				}
			}
			else {
				auto t1 = s.replaceAll(regex(split_on), "$1\n");
				if ("en" == language) {
					/* nothing else was needed */
				}
				else {
					//Added for French, but none is really specific to that corpus.
					t1 = s
						.replaceAll(regex(split_on), "$1\n")
						.replaceAll(regex(` "`), "\n \"")
						.replaceAll(regex(`" `), "\" \n")
					;
				}

				if ("fr" == language) {
					//This, on the other hand, probably is French-only
					t1 = t1.replaceAll(regex(`» `), "» \n");
				}
				foreach (t; t1.splitter("\n")) {
					yield(t);
				}
			}

			if (mark_newlines) {
				lineno_nodocs++;
				yield("<NEWLINE>");
			}
			else {
				lineno_docs++;
			}
		}
	});
}

auto mergefiles(T1, T2)(T1 corpus_no_docs, T2 corpus_with_docs) {
	return new Generator!string({
		auto fname = "", chapter = "";

		string next_nontag(T)(T source) {
			if (source.empty) return "<EOF>";//Can happen during recursive calls.  The empty string will end up being replaced by a blank line in the end
			auto s = source.front();
			source.popFront();

			if (!s.strip().length) return next_nontag(source);
			
			if ('<' != s[0]) return s;
			
			//TODO: time matchFirst(`foo`) vs. matchFirst(regex(`foo`)) vs. auto r = regex(`foo`); matchFirst(r);
			if (s.matchFirst(`<NEWLINE>$`)) {
				yield(s);
			}
			else if (s.matchFirst(`<FILE ID=`)) {
				fname = s.replaceFirst(regex(`<FILE ID=(.*)>`), "$1");
			}
			else if (s.matchFirst(`<CHAPTER ID=`)) {
				chapter = s.replaceFirst(regex(`<CHAPTER ID=(.*)>`), "$1");
				yield(format("<CHAPTER ID=%s.%s>", fname, chapter));
			}
			return next_nontag(source);
		}

		bool similar(string a, string b) {
			static auto r = regex(" +");
			auto s = b.strip().replaceAll(r, " ");
			static if (DEBUG_LEVEL >= 1) stderr.writef("CANDIDATE: '%s'\n", s);
			return a.strip().replaceAll(r, " ") == s;
		}

		while (!corpus_no_docs.empty && !corpus_with_docs.empty) {
			//auto expect = corpus_no_docs.next_nontag();
			auto expect = next_nontag(corpus_no_docs);
			static if (DEBUG_LEVEL >= 1) stderr.writef("EXPECT: '%s'\n", expect);

			auto prevline = "";
			for (auto nmisses = 0; 1; nmisses++) {
				//skip the ones that aren't in the non-tagged corpus
				auto found = next_nontag(corpus_with_docs);
				if ("<EOF>" == found && "<EOF>" != expect) {
					stderr.writef("ERROR: EOF in marked corpus but not in unmarked\n");
					break;
				}
				if (similar(expect, found)) {
					yield(expect);
					if (nmisses >= 10000) {
						stderr.writef("%s, %s: Found it.\n", lineno_nodocs, lineno_docs);
					}
					prevline = "";
					break;
				}
				else if (similar(expect, prevline ~ " " ~ found)) {
					/* TODO: It'd be nice if I could look ahead on the expect side as well.  If expect is a subsequence
					   of found, it won't match.  But I don't want to just remove the part that does match from found and
					   move on to the next expect, since that potentially will match things it shouldn't and screw up the
					   synchronization. */
					stderr.writef("%s, %s: Combining lines (from the tagged corpus) \"%s\", \"%s\" to form match\n", lineno_nodocs, lineno_docs, prevline, found);
					yield(expect);
					prevline = "";
					break;
				}
				else if (similar(expect ~ " " ~ corpus_no_docs.front(), found)) {
					//NOTE: This can never happen, since the <NEWLINE> tags will be in the way
					stderr.writef("%s, %s: Combining lines (from the untagged corpus) \"%s\", \"%s\" to form match\n", lineno_nodocs, lineno_docs, prevline, found);
					yield(found);
					prevline = "";
					corpus_no_docs.popFront();
					break;
				}

				prevline = found;
				if (nmisses > 0 && 0 == nmisses % 10000) {
					if (nmisses < 100000 || 0 == nmisses % 100000) {
						stderr.writef("%s, %s: %s failed candidates for '%s'\n", lineno_nodocs, lineno_docs, nmisses, expect);
					}
				}
			}
		}
	});
}

int run(string fname_no_docs, string fname_with_docs) {
	auto corpus_no_docs = splitlines(fname_no_docs, 1);
	auto corpus_with_docs = splitlines(fname_with_docs, 0);

	auto s = "";
	foreach (line; mergefiles(corpus_no_docs, corpus_with_docs)) {
		if (line.matchFirst("^<CHAPTER")) {
			if (s.length) {
				stderr.writef("%s, %s: assertion failure: buffer not empty at start of chapter\ns = \"%s\"", lineno_nodocs, lineno_docs, s);
				assert(!s.length);
			}
			writef("%s\n", line);
		}
		else if ("<NEWLINE>" == line) {
			if (s.length) writef("%s\n", s[1..$]);//skip the extra space at the beginning
			s = "";
		}
		else {
			s ~= " " ~ line;
		}
	}
	if (s.length) writef("%s\n", s[1..$]);//EOF acts like <NEWLINE>

	return 0;
}

void dump_intermediate(string fname_no_docs, string fname_with_docs) {
	auto corpus_no_docs = splitlines(fname_no_docs, 1);
	auto corpus_with_docs = splitlines(fname_with_docs, 0);

	{
		auto f = File("corpus_no_docs.txt", "w");
		foreach (line; corpus_no_docs) {
			f.writeln(line);
		}
	}
	{
		auto f = File("corpus_with_docs.txt", "w");
		foreach (line; corpus_with_docs) {
			f.writeln(line);
		}
	}
}

int main(string[] argv) {
	string corpus_no_docs, corpus_with_docs;
	bool save_intermediate = 0;
	alias R = std.getopt.config.required;
	auto opts = getopt(argv,
		"lang|l", "language of corpus", &language,
		R, "aligned", "sentence aligned corpus.  e.g. europarl-v7.fr-en.en", &corpus_no_docs,
		R, "tagged", "corpus containing <CHAPTER> tags (cleaned version of the txt/LANG/ep*.txt files)", &corpus_with_docs,
		"save-intermediate-files|s", "if set, preprocessed (but not yet merged) versions of each file will be saved", &save_intermediate
	);

	if (opts.helpWanted) {
		defaultGetoptPrinter("Arguments", opts.options);
		return 1;
	}   

	auto languages = [ "en", "fr" ];
	assert(languages.count(language) > 0);
	stderr.writef("Language: %s", language);

	try {
		//TODO: If we saved the intermediate files, read from *those* instead of redoing the work?
		if (save_intermediate) {
			dump_intermediate(corpus_no_docs, corpus_with_docs);
		}
		run(corpus_no_docs, corpus_with_docs);
	}
	catch (Exception e) {
		stderr.writeln(e.info);
	}
	return 0;
}

