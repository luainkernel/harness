#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# A reply that says the session can be cleared, or that ends a turn which wrote the session's hand-off,
# ends on the clear notice, the block --block prints, set apart from the text above it: the maintainer
# missed "a sessão pode ser limpa" in bold inside a reply, "a comunicacao visual do pedido de clear nao
# foi respeitada". The turn began at the last prompt the transcript holds. Names a reply that does not
# end on the block, with the block, or one that points at a hand-off never written, and exits 1.
#
# Usage: bash tools/checks/clear-notice.sh <reply> <hand-off> [<transcript>]
#        bash tools/checks/clear-notice.sh --block <hand-off>   prints the block

block() {
	printf -- '---\n\n# 🧹🧹🧹 PODE LIMPAR A SESSÃO 🧹🧹🧹\n\n1. `/clear`\n2. `continue`\n\nHand-off: `%s`\n\n---' "$1"
}

if [ "$1" = --block ]; then
	block "$2"
	echo
	exit 0
fi

reply=$1
handoff=$2
transcript=$3
[ -f "$reply" ] || exit 0

clears='\bpode(m)?( j[aá])? (ser limp|limpar a sess|dar (um )?/?clear)|\b(can|may) (now )?be cleared\b|\b(safe|ready) to (be )?clear\b|\bclear (the|this) session\b'

# whether the hand-off was written since the turn began: its mtime against the last prompt's timestamp,
# a prompt being what no tool result or note of Claude Code's is
written() {
	[ -f "$handoff" ] && [ -f "$transcript" ] || return 1
	local began
	# head, not jq's first(): jq 1.6's fromjson? catches the break first() stops on, and prints every prompt
	began=$(tac "$transcript" | jq -Rr 'fromjson? | select(.type == "user" and (.isMeta | not) and
		(.message.content | type == "string" or all(.[]?; .type != "tool_result"))) | .timestamp' | head -n 1)
	[ -n "$began" ] && [ "$(date -r "$handoff" +%s)" -ge "$(date -d "$began" +%s)" ]
}

# a phrase quoted, or code, is one talked about, not one said
sed -E 's/`[^`]*`//g; s/"[^"]*"//g; s/[*_]//g' "$reply" | grep -qiE "$clears" || written || exit 0

if [ ! -f "$handoff" ]; then
	echo "$reply: says the session can be cleared, and no hand-off was written to $handoff; write it, then end the reply on the clear notice"
	exit 1
fi
# the reply's last lines, trailing spaces dropped, against the block's, a blank line above it
BLOCK=$(block "$handoff") awk 'BEGIN { n = split(ENVIRON["BLOCK"], want, "\n") }
	{ sub(/[[:space:]]+$/, ""); line[NR] = $0; if ($0 != "") last = NR }
	END {
		if (last < n) exit 1
		for (i = 1; i <= n; i++) if (line[last - n + i] != want[i]) exit 1
		exit !(last == n || line[last - n] == "")
	}' "$reply" && exit 0
echo "$reply: ends without the clear notice, where it says the session can be cleared or ends the turn that wrote its hand-off; end it on these lines, a blank line above them:"
block "$handoff"
echo
exit 1

