#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Sets the agent-review status, which merge-guard.sh reads, on the commit <sha> of the repository
# <owner>/<repo>, and only on the record of an agent's review that passed it. A head passes when the
# newest reviewer at high effort or above, the agent a workflow labels review:<pr or branch> as review.js
# labels its Review phase, alone or nested in implement-issue, of a tip whose tree is the head's returned
# ready, with no mechanism kept without a source unless its run's replaces names smallest (review.js).
# Its answer is read in its run's journal, before a reader of the body sets the run's ready to false,
# since the body is held to its reader as it opens, and its effort in its transcript, both under Claude
# Code's projects directory. The commit a rebase merge put
# on the trunk passes when a reviewer so returned the head of the pull request it merged, or that pull
# request merged on its proof (the merged skill, sections 0 and 5). The session runs it under a narrow
# permissions.allow rule: the auto mode classifier refuses the session's own write of the status where
# no order of the maintainer's is in the conversation, as after a /clear.
#
# Usage: bash tools/agent-review.sh <owner>/<repo> <sha> <file that holds the token>

[ $# -eq 3 ] || { echo "usage: $0 <owner>/<repo> <sha> <token file>" >&2; exit 2; }
. "$(dirname "$(readlink -f "$0")")/checks/commands.sh"

repo=$1
GH_TOKEN=$(cat "$3" 2> /dev/null)
export GH_TOKEN
projects=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects

refuse() {
	echo "agent-review: $*, so no status is set" >&2
	exit 1
}

# the tree of the commit <sha>, read in the checkout <dir> when it holds the commit, else on GitHub
tree() {
	git -C "${2:-.}" rev-parse -q --verify "$1^{tree}" 2> /dev/null ||
		gh api "repos/$repo/git/commits/$1" --jq .tree.sha 2> /dev/null
}

# each reviewer of the repository's runs, newest first, a line each: when its run ended, whether it
# returned ready with no mechanism kept without a source, its tip, its transcript and the checkout its run
# worked in
reviewers() {
	local journal run meta stamp replaced checkout
	grep -l '"label":"review:' "$projects"/*/*/subagents/workflows/*/journal.jsonl 2> /dev/null | while IFS= read -r journal; do
		run=$(dirname "$journal")
		# a run a /clear crossed has its journal in the session that launched it, its record in the next
		meta=$(jq -er --arg repo "$repo" 'select((.args.github? // "" | ascii_downcase) == ($repo | ascii_downcase)) |
			[.timestamp, ([.args.replaces // "" | splits("\\s+")] | any(. == "smallest")), .args.repo // ""] | @tsv' \
			"${run%/*/subagents/workflows/*}"/*/workflows/"${run##*/}".json 2> /dev/null) || continue
		read -r stamp replaced checkout <<< "$meta"
		jq -rs --arg stamp "$stamp" --arg run "$run" --arg checkout "$checkout" --arg replaced "$replaced" '
			[.[] | select(.type == "started" and (.label // "" | startswith("review:"))) | .agentId] as $reviewers
			| [.[] | select(.type == "result" and (.agentId as $id | $reviewers | any(. == $id)) and (.result.tip // "") != "")] | reverse[]
			| (.result.ready == true and ($replaced == "true" or
				([.result.smallest.beyond[]? | select(.verdict == "kept" and ((.source // "") | test("^\\s*$")))] | length == 0))) as $ready
			| [$stamp, (if $ready then "ready" else "not" end), .result.tip, "\($run)/agent-\(.agentId).jsonl", $checkout]
			| @tsv' "$journal" 2> /dev/null
	done | sort -s -r -t $'\t' -k 1,1
}

# the status's description when the newest review, at high effort or above, of the commit <sha> or of one
# of the tree <tree> returned it ready; nothing, and a failure, when none did or the newest did not
recorded() {
	local stamp verdict tip transcript checkout effort
	while IFS=$'\t' read -r stamp verdict tip transcript checkout; do
		[ "$tip" = "$1" ] || [ "$(tree "$tip" "$checkout")" = "$2" ] || continue
		effort=$(jq -r 'select(.type == "assistant") | .effort // empty' "$transcript" 2> /dev/null | tail -n 1)
		case $effort in
		high|xhigh|max) ;;
		*) continue ;;
		esac
		[ "$verdict" = ready ] || return 1
		echo "review.js: ready, $(basename "$(dirname "$transcript")") at $effort"
		return
	done < <(reviewers)
	return 1
}

# gh prints the body of an error where the answer would be, so each lookup is read by its exit status
commit=$(gh api "repos/$repo/commits/$2" --jq '[.sha, .commit.tree.sha] | @tsv' 2> /dev/null) ||
	refuse "GitHub did not answer for $2 in $repo"
read -r sha tree <<< "$commit"

if ! description=$(recorded "$sha" "$tree"); then
	merged=".[] | select(.merged_at != null and .merge_commit_sha == \"$sha\") | [.number, .head.sha] | @tsv"
	pulls=$(gh api "repos/$repo/commits/$sha/pulls" --jq "$merged" 2> /dev/null) ||
		refuse "GitHub did not answer for the pull requests of ${sha:0:9}"
	read -r number head <<< "$(printf '%s\n' "$pulls" | head -n 1)"
	if [ -z "$number" ]; then
		refuse "the newest review at high effort of ${sha:0:9}, or of a commit of its tree, is not ready or none ran, and no pull request merged as it"
	# a base that moved before the merge gives the trunk commit a tree no reviewer returned
	elif reviewed=$(recorded "$head" "$(tree "$head")"); then
		description="merged from #$number, $reviewed"
	elif gh_proved "$repo" "$number" "$(gh api user --jq .login 2> /dev/null)" "$head"; then
		description="merged from #$number on its proof"
	else
		refuse "the newest review at high effort of ${head:0:9}, the head of #$number, is not ready or none ran," \
			"nor does a proof name it"
	fi
fi

gh api -X POST "repos/$repo/statuses/$sha" -f state=success -f context=agent-review -f description="$description" \
	--jq .state > /dev/null || refuse "GitHub refused the status on ${sha:0:9}"
echo "agent-review: ${sha:0:9}: $description"

