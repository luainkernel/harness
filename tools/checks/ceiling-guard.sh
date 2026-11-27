#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# PreToolUse hook: a workflow agent whose prompt sets a context ceiling stops working past it, closes
# its checkpoint and returns, and the workflow launches one in its place that reads the checkpoint
# first (luainkernel/harness#6, D192). Its prompt names the ceiling and the checkpoint on a line of
# its own, `CONTEXT CEILING: <tokens> tokens, checkpoint <path>`, which implement.js and review.js
# write when a launch names args.ceiling. The call carries the agent's agent_id and the session's
# transcript_path, beside which the agent's own transcript sits,
# <session>/subagents/workflows/<run>/agent-<agent_id>.jsonl, read as context.sh reads a session's.
# Past the ceiling, blocks (exit 2) every call but the agent's answer, StructuredOutput, one whose
# input names the checkpoint and a shell call that runs git and cd alone, but for the `$(cat <file>)`
# a push's URL reads its token with, so the agent is left the calls that write where it is and commit
# and push what is done. Silent (exit 0) on a call of a session's own thread, of an agent whose
# prompt sets no ceiling, and below it.

input=$(cat)

case "$input" in
	*'"agent_id"'*) ;;
	*) exit 0 ;;
esac

field() {
	printf '%s' "$input" | jq -r "$1 // empty" 2> /dev/null
}

agent=$(field .agent_id)
session=$(field .transcript_path)
[ -n "$agent" ] && [ -n "$session" ] || exit 0
for transcript in "${session%.jsonl}"/subagents/workflows/*/"agent-$agent.jsonl"; do
	[ -f "$transcript" ] && break
done
[ -f "$transcript" ] || exit 0

# the prompt opens the transcript, after the request a workflow relays ahead of it
read -r ceiling checkpoint < <(head -n 5 "$transcript" | jq -r 'select(.type == "user") | .message.content | strings' 2> /dev/null |
	sed -nE 's/^[[:space:]]*CONTEXT CEILING: ([0-9]+) tokens, checkpoint ([^[:space:]]+)$/\1 \2/p' | head -n 1)
[ -n "$ceiling" ] || exit 0
context=$(bash "$(dirname "$0")/context.sh" "$transcript" "$ceiling")
[ -n "$context" ] || exit 0

[ "$(field .tool_name)" = StructuredOutput ] && exit 0
field '.tool_input | tostring' | grep -qF -- "$checkpoint" && exit 0
if [ "$(field .tool_name)" = Bash ]; then
	. "$(dirname "$0")/commands.sh"
	cmds=$(commands "$input")
	text=$(command_text "$input")
	# beside git and cd, the file a push's URL substitutes, the token it authenticates with
	left=$(printf '%s\n' "$cmds" | grep -Ev "$GIT_COMMAND |^cd( |\$)" | while IFS= read -r cmd; do
		[[ $cmd =~ ^cat\ [^\ ]+$ && $text == *"\$($cmd)"* ]] || printf '%s\n' "$cmd"
	done)
	[ -n "$cmds" ] && [ -z "$left" ] && exit 0
fi

echo "ceiling-guard: your context carries $context tokens, past the ceiling of $ceiling your prompt sets. Write in $checkpoint where you are, the worktree and what is left, commit and push what is done, and answer with ceiling true and the rest of your answer as far as it stands: the workflow launches an agent in your place that reads the checkpoint first. From here only a call that names the checkpoint, git and your answer run." >&2
exit 2

