#!/usr/bin/awk -f

is_doc = 0
/<\/doc>/ {
	if (last_was_doc) next
	is_doc = 1
}

{
	last_was_doc = is_doc
	print
}
