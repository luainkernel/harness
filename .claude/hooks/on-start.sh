#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# SessionStart adapter, on a start and after a clear: a session whose context passed 300k tokens
# writes a hand-off under scratch/handoff/ at a boundary and is cleared (on-prompt.sh), and the state
# it held, the open decisions, the runs in flight and the pull requests that wait, is in that file
# alone. This lists the hand-offs there, newest first, to the session that starts; silent when none.

dir=${CLAUDE_PROJECT_DIR:-.}/scratch/handoff
handoffs=$(ls -t "$dir" 2> /dev/null)
[ -n "$handoffs" ] || exit 0

echo "Hand-offs a session left in $dir before it was cleared, newest first; the one this session continues is read before anything else:"
while read -r name; do
	printf '%s  %s\n' "$(date -r "$dir/$name" '+%F %R')" "$dir/$name"
done <<< "$handoffs"
exit 0

