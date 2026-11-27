#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# A call the conventions settle is made, not handed to the maintainer: a finding goes to an issue, and
# the reply says its number. "Decisão: o ponto cego do crash-guard.sh vira issue?" asked him twice
# what the review's filing stage does unasked, and "gravo o `Update:` do groomer na #2118?" asked him,
# a fourth time, to post what an implement-issue run returns, which he ordered posted always, as he
# ordered every post on 2026-11-27. Takes text files, a reply among them; prints each decision line
# that asks either, and exits 1.
#
# Usage: bash tools/checks/settled.sh <file>...

settled='(decis(a|ã)o|decision):.*\b(vira(r)?|abr(e|ir|o)|registr(a|ar|o)|file|open)\b( (uma|um|an?|the))? (issue|issues)\b'
# the Update a run returns is named in code, `Update:`, so this reads the line with its code; a post
# is any, asked as a verb before its object or the question mark, since the noun, `-X POST` and a
# hyphen's name, review-post-guard, ask nothing
posted='(decis(a|ã)o|decision):.*(\b(grav(a|ar|o)|append|write)\b.*\b(update|label)\b|(^|[^-[:alnum:]_])(post(a|ar|o)?|publi(ca|car|co|sh))( (o|a|os|as|um|uma|the|this|these|that|it|them|an?|agora|now|j(a|á))\b|[[:space:]]*(\?|$)))'

status=0
for file in "$@"; do
	[ -f "$file" ] || continue
	# a phrase quoted, or code, is one talked about, not one said
	if asks=$(sed -E 's/`[^`]*`//g; s/"[^"]*"//g; s/[*_]//g' "$file" | grep -niE "$settled"); then
		printf '%s\n' "$asks" | sed "s|^|$file:|"
		echo "$file: asks whether to file a finding, which the conventions settle; file it and say its number"
		status=1
	fi
	if asks=$(sed -E 's/"[^"]*"//g; s/[*_`]//g' "$file" | grep -niE "$posted"); then
		printf '%s\n' "$asks" | sed "s|^|$file:|"
		echo "$file: asks whether to post, which the maintainer ordered done with no OK of his on the text; post it"
		status=1
	fi
done
exit $status

