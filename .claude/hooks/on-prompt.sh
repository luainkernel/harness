#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# UserPromptSubmit adapter: reads the maintainer's message through tools/checks/question.sh and, when
# it asks rather than directs, adds to the turn that it answers and changes nothing, and through
# tools/checks/table.sh and, when it asks for a table, how much a cell holds for the table to be drawn,
# and reads the session's transcript through tools/checks/context.sh and, when its last request carried
# more than 300k tokens of context, that the session writes a hand-off at the next boundary and says it
# can be cleared; the checks are plain path-taking scripts (.agents/rules/checks.md), this only
# translates.

input=$(cat)
command -v jq > /dev/null || exit 0

prompt=$(mktemp) || exit 0
trap 'rm -f "$prompt"' EXIT
printf '%s' "$input" | jq -r '.prompt // empty' > "$prompt"
# a background task's notification reaches the turn as a prompt, and the maintainer wrote none of it
grep -q '^<task-notification>' "$prompt" && exit 0

checks="$(dirname "$0")/../../tools/checks"
ctx=
[ -n "$(bash "$checks/question.sh" "$prompt")" ] &&
	ctx='[question] The maintainer asked, and did not direct: this turn answers, and changes nothing. No edit, commit, push, workflow, agent or GitHub write until he says to; a step the answer recommends is proposed with its decision, not taken. A question mark after text that directs, "...; entendido?", still asks: say what you would do and wait for the go.'
[ -n "$(bash "$checks/table.sh" "$prompt")" ] &&
	ctx="${ctx:+$ctx }"'[table] A table in the reply is drawn as one only while it fits: Claude Code wraps each cell to the width its column gets, and when a cell runs past four lines, or the table past the terminal, it prints every row as "Header: value" lines instead, which is not the table asked for. Each cell holds a few words, under 40 characters, in five columns at most; what does not fit goes in a list below the table, keyed by the first column.'
context=$(bash "$checks/context.sh" "$(printf '%s' "$input" | jq -r '.transcript_path // empty')")
[ -n "$context" ] &&
	ctx="${ctx:+$ctx }[handoff] This session's last request carried $((context / 1000))k tokens of context, and every request after it carries them again. At the next boundary, a run returned or a pull request merged, write the hand-off to ${CLAUDE_PROJECT_DIR:-.}/scratch/handoff/$(printf '%s' "$input" | jq -r '.session_id').md: the open decisions by their IDs, the runs in flight with their scratch directories and the pull requests that wait; then say in the reply that the session can be cleared. The session started after the clear is shown the hand-offs there."
[ -n "$ctx" ] || exit 0

jq -cn --arg ctx "$ctx" \
	'{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
exit 0

