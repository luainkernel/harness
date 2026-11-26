#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Stop adapter: reads the reply a turn ends on through tools/checks/decision.sh,
# tools/checks/reboot-capture.sh, tools/checks/handoff.sh, tools/checks/citation.sh,
# tools/checks/tldr.sh, tools/checks/settled.sh and tools/checks/clear-notice.sh and sends it back once
# when it hands the maintainer a decision without the question, the options and a recommendation, or
# recommends an option for keeping an API, asks for a reboot
# nothing captured for, hands him a long command to copy, cites a rule it does not quote from the
# tree, runs long without a TL;DR, asks him whether to file a finding, or says the session can be
# cleared, or ends the turn that wrote its hand-off, without the clear notice; the checks are plain
# path-taking scripts (.agents/rules/checks.md), this only translates.

input=$(cat)
command -v jq > /dev/null || exit 0
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = true ] && exit 0

reply=$(mktemp) || exit 0
trap 'rm -f "$reply"' EXIT
printf '%s' "$input" | jq -r '.last_assistant_message // empty' > "$reply"
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
if [ ! -s "$reply" ]; then
	[ -f "$transcript" ] || exit 0
	tail -n 200 "$transcript" | jq -rs '[.[] | select(.type == "assistant") | .message.content[]? |
		select(.type == "text") | .text] | last // empty' > "$reply" 2> /dev/null
fi
[ -s "$reply" ] || exit 0

checks="$(dirname "$0")/../../tools/checks"
# the hand-off on-prompt.sh names for this process and session
handoff=${CLAUDE_PROJECT_DIR:-.}/scratch/handoff/${CLAUDE_PID:+$CLAUDE_PID-}$(printf '%s' "$input" | jq -r '.session_id').md
findings=$(for check in decision reboot-capture handoff citation tldr settled; do bash "$checks/$check.sh" "$reply"; done
	bash "$checks/clear-notice.sh" "$reply" "$handoff" "$transcript")
[ -n "$findings" ] || exit 0
jq -n --arg reason "${findings//$reply/the reply}" '{decision: "block", reason: $reason}'
exit 0

