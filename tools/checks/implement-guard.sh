#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# PreToolUse (Bash) hook: an implementation is written by implement-issue's agents, so its implementer
# and its review are not the session's (AGENTS.md, "Skills"); #1894 was written in the thread of the
# session that reviewed #1893, and the maintainer sent the shape after it to implement-issue. This
# blocks (exit 2) a git commit in the session's own thread that stages code, a path the code key of the
# tree's .agents/harness.conf matches (project.sh), staged before the call or by a git add in it, unless
# the commit is a fixup, a squash or an amend, which correct a commit a review reads, or the command
# carries IMPLEMENT_OK=1, set when the maintainer asked the session to write it. Silent (exit 0) on
# everything else, and on a tree whose project names no code.

input=$(cat)

. "$(dirname "$0")/commands.sh"

case "$(command_words "$input")" in
	*"git "*commit*) ;;
	*) exit 0 ;;
esac

# a call inside a subagent carries agent_id, one of the main thread never does
[ -n "$(printf '%s' "$input" | jq -r '.agent_id // empty' 2> /dev/null)" ] && exit 0

case "$(command_text "$input")" in
	*IMPLEMENT_OK=1*) exit 0 ;;
esac

cmds=$(commands "$input")
cwd=$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
added=$(git_runs "$cmds" "$cwd" add)

staged=$(git_runs "$cmds" "$cwd" commit | while IFS=$'\t' read -r dir rest; do
	case " $rest " in
		*" --fixup"*|*" --squash"*|*" --amend"*|*" -m fixup! "*|*" -m squash! "*|*" -m amend! "*) continue ;;
	esac
	code=$(project_conf code "$dir")
	[ -n "$code" ] || continue
	{
		git -C "$dir" diff --cached --name-only 2> /dev/null
		printf '%s\n' "$added" | awk -F'\t' -v dir="$dir" '$1 == dir { print $2 }' | tr ' ' '\n'
	} | grep -E "$code"
done | sort -u)
[ -n "$staged" ] || exit 0

echo "implement-guard: this commit, in the session's own thread, carries code ($(paste -sd' ' <<< "$staged")); an implementation goes to agents through implement-issue (AGENTS.md, \"Skills\"), and a correction is git commit --fixup=<hash>. IMPLEMENT_OK=1, as a command prefix, commits one the maintainer asked the session itself to write." >&2
exit 2

