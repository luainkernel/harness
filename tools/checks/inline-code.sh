#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Names the code of another language a shell script carries inline: an interpreter of Lua, Python,
# Perl, Ruby or Node that runs code from its -e, Python's -c, or from a heredoc when it is given - or no
# script, and a heredoc a command writes into a program file, one named .lua, .py, .pl, .rb, .js or
# .c. Such code is a file of its own beside the script, as the maintainer decided in the review of
# luainkernel/lunatik#2724, "isso eh sujo e deveriamos ter regras contra isso no harness.. claro que
# tem que ir prum arquivo proprio"; awk and sed one-liners stay.
#
# Heuristic: it nudges at edit time and in review, it does not rewrite. Reads the lines the
# diff against CHECK_BASE (default HEAD) adds, every line of a file the repository does not
# track, a line a backslash continues read with the next; prints one finding per line and exits 1
# when there are any. Files outside its scope are skipped silently, so callers can pass any path.
#
# Usage: [CHECK_BASE=origin/master] bash tools/checks/inline-code.sh <file>...

status=0
base=${CHECK_BASE:-HEAD}

. "$(dirname "$(readlink -f "$0")")/added.sh"

for file in "$@"; do
	case "$file" in
		*.sh) ;;
		*) [[ ${file##*/} != *.* && $(head -n 1 "$file" 2> /dev/null) =~ ^#!.*[/\ ](ba|da)?sh([[:space:]]|$) ]] || continue ;;
	esac
	[ -f "$file" ] || continue
	lines=$(added "$file")
	[ -n "$lines" ] || continue

	awk -v file="$file" -v lines="$lines" '
	BEGIN {
		all = (lines == "all"); split(lines, a, "\n"); for (i in a) if (a[i] != "") isadded[a[i]] = 1
		python = "python[0-9.]*"
		others = "(lua(jit|[0-9.]+)?|perl|ruby|node(js)?)"
		interp = "(" python "|" others ")"
		# where a command opens, past the assignments and the words that lead into it
		lead = "(^|[;|&(`]|(then|do|else)[[:space:]])[[:space:]]*(([A-Za-z_][A-Za-z_0-9]*=[^[:space:]]*|env|sudo|exec|command|time)[[:space:]]+)*([^[:space:]]*/)?"
		flags = "([[:space:]]+-[A-Za-z]+)*"
		# python takes its code from -c and the others from -e: the -c of perl, ruby and node checks a script
		inline = lead "(" python flags "[[:space:]]+-[A-Za-z]*c|" others flags "[[:space:]]+-[A-Za-z]*e)([[:space:]\047\"]|$)"
		# given - or no script, it reads its code from stdin
		stdin = lead interp flags "([[:space:]]+-([[:space:]]|$)|[[:space:]]*($|[0-9&]*[<>]))"
		target = "(>>?[[:space:]]*|(^|[;|&(])[[:space:]]*tee" flags "[[:space:]]+)[^[:space:]<>|;&]*\\.(lua|py|pl|rb|js|c)[\"\047]?([[:space:]]|$)"
	}
	# the line of the file L holds at pos
	function at(pos,   k) {
		for (k = nk; k > 1 && start[k] > pos; k--)
			;
		return num[k]
	}
	function report(pos, what,   n) {
		n = at(pos)
		if (all || n in isadded) {
			printf "%s:%d: %s: that code is a file of its own beside the script\n", file, n, what
			found = 1
		}
	}
	# the interpreter the command at pos..pos+len runs, in name; returns where its name starts
	function interpreter(pos, len,   m, p) {
		m = substr(L, pos, len)
		match(m, "(^|[[:space:];|&(`/])" interp "([[:space:]]|$)")
		name = substr(m, RSTART, RLENGTH)
		p = RSTART
		if (name ~ /^[[:space:];|&(`\/]/) {
			name = substr(name, 2)
			p++
		}
		sub(/[[:space:]]$/, "", name)
		return pos + p - 1
	}
	/^[[:space:]]*#/ && L == "" { next }
	{
		start[++nk] = length(L) + 1
		num[nk] = NR
		L = L $0
		if (L ~ /\\$/) {
			L = substr(L, 1, length(L) - 1) " "
			next
		}
		heredoc = L ~ /(^|[^<])<<[^<]/
		if (match(L, inline)) {
			flag = substr(L, RSTART, RLENGTH)
			pos = interpreter(RSTART, RLENGTH)
			sub(/[[:space:]\047"]$/, "", flag)
			match(flag, /-[A-Za-z]*[ce]$/)
			report(pos, name " runs code from its " substr(flag, RSTART, RLENGTH))
		}
		else if (heredoc && match(L, stdin))
			report(interpreter(RSTART, RLENGTH), name " runs code from a heredoc")
		if (heredoc && match(L, target)) {
			pos = RSTART
			name = substr(L, RSTART, RLENGTH)
			sub(/[[:space:]]+$/, "", name)
			sub(/.*[\/>[:space:]]/, "", name)
			gsub(/["\047]/, "", name)
			report(pos, "a heredoc writes " name)
		}
		L = ""
		nk = 0
	}
	END { exit found }
	' "$file" || status=1
done
exit $status

