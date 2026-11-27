#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Merges the pull request <N> of the repository <owner>/<repo> by rebase, its head named, and only where
# checks/merge-guard.sh, handed the command this runs, passes it: a harness pull request whose head a
# review passed or a proof names, and a bump of the mount (the merged skill, sections 0 and 5). The
# command never carries MERGE_OK=1, which the guard reads in the command alone, so nothing the guard
# refuses merges here. The session runs it under a narrow permissions.allow rule: the auto mode
# classifier refuses the session's own merge where no order of the maintainer's is in the
# conversation, as after a /clear. Prints GitHub's answer, whose sha is the commit the merge put on the
# trunk.
#
# Usage: bash tools/merge.sh <owner>/<repo> <N> <head> <file that holds the token>

[ $# -eq 4 ] && [[ $1 =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ && $2 =~ ^[0-9]+$ && $3 =~ ^[0-9a-f]{40}$ ]] ||
	{ echo "usage: $0 <owner>/<repo> <N> <full head sha> <token file>" >&2; exit 2; }

GH_TOKEN=$(cat "$4" 2> /dev/null)
export GH_TOKEN
merge=(gh api -X PUT "repos/$1/pulls/$2/merge" -f merge_method=rebase -f sha="$3")

jq -nc --arg command "${merge[*]}" '{tool_name: "Bash", tool_input: {command: $command}}' |
	bash "$(dirname "$(readlink -f "$0")")/checks/merge-guard.sh" || exit 1
"${merge[@]}"

