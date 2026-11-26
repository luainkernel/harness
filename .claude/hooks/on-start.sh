#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# SessionStart adapter, on a start and after a clear: a session whose context passed 300k tokens
# writes a hand-off under scratch/handoff/ at a boundary and is cleared (on-prompt.sh), and the state
# it held, the open decisions, the runs in flight and the pull requests that wait, is in that file
# alone. This lists the hand-offs there, newest first, to the session that starts, and names the one a
# first message of only "continue" continues: the newest its own Claude Code process wrote, the
# CLAUDE_PID a clear keeps, else the newest whose process no longer runs; silent when none.

dir=${CLAUDE_PROJECT_DIR:-.}/scratch/handoff
handoffs=$(ls -t "$dir" 2> /dev/null)
[ -n "$handoffs" ] || exit 0

# the process that wrote the hand-off <name>, which on-prompt.sh names <pid>-<session>.md
writer() {
	[[ $1 =~ ^([0-9]+)- ]] && printf '%s' "${BASH_REMATCH[1]}"
}

# whether the process <pid> still runs: its session continues its own hand-off
running() {
	[ -n "$1" ] && kill -0 "$1" 2> /dev/null
}

continued=
while read -r name; do
	pid=$(writer "$name")
	if [ -n "$CLAUDE_PID" ] && [ "$pid" = "$CLAUDE_PID" ]; then
		continued=$name
		break
	fi
	[ -n "$continued" ] || running "$pid" || continued=$name
done <<< "$handoffs"

echo "Hand-offs a session left in $dir before it was cleared, newest first; the one this session continues is read before anything else${continued:+, and a first message that says only \"continue\" continues $dir/$continued}:"
while read -r name; do
	printf '%s  %s\n' "$(date -r "$dir/$name" '+%F %R')" "$dir/$name"
done <<< "$handoffs"
exit 0

