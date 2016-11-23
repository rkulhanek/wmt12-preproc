/* Removes both the blank line *and* the corresponding line from the other language's corpus. 
   This is how the europarl site recommends dealing with that issue when using the corpus with things
   like Giza++ */

import std.stdio, std.range, std.getopt, std.format, std.algorithm;

int main(string[] argv) {
	string src, targ, in_prefix, out_prefix;

	alias R = std.getopt.config.required;
	auto opts = getopt(argv,
		R, "src", "source language", &src,
		R, "targ", "target language", &targ,
		R, "input-prefix", &in_prefix,
		R, "output-prefix", &out_prefix
	);

	if (opts.helpWanted) {
		defaultGetoptPrinter("Arguments", opts.options);
		stderr.writef("Will read input-prefix.src-targ.src and input-prefix.src-targ.targ, and write to output-prefix.src-targ.[src,targ]\n");
		return 1;
	}

	auto in_src = format("%s.%s-%s.%s", in_prefix, src, targ, src);
	auto in_targ = format("%s.%s-%s.%s", in_prefix, src, targ, targ);
	
	auto out_src = File(format("%s.%s-%s.%s", out_prefix, src, targ, src), "w");
	auto out_targ = File(format("%s.%s-%s.%s", out_prefix, src, targ, targ), "w");

	//remove blank lines
	auto r = zip(File(in_src).byLine, File(in_targ).byLine)
		.filter!"a[0].length && a[1].length";

	foreach(a; r) {
		out_src.writeln(a[0]);
		out_targ.writeln(a[1]);
	}

	return 0;
}

