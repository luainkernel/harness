#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# PreToolUse (Bash) hook: the session merges a pull request without the maintainer only when the
# posting account opened it on the repository's default branch, it changes the harness alone, its head carries the
# agent-review status, or the pull request is small by complexity.sh and a comment of the posting account
# on it names the head, and passed every check run, and none of its commits waits for a squash, which
# the Checks run warns of without failing (CONVENTIONS.md, "Patches and commits"). A repository whose CI
# runs no job, which a line "<owner>/<name> <ERE>" of $HARNESS_LOCAL_GATES names in the machine's
# environment, passes where its head has no check run on a comment of the posting account that names
# the head and holds a line the ERE matches, the one its local gate prints on a pass. A bump of the mount, whose
# one file is the submodule, carries the agent-review status of the harness commit it pins instead, a
# commit on the harness's trunk that passed every check run of its own (the merged skill, section 5).
# A pull request of the harness's own repository, by the name its checkout's origin gives, is the
# harness whole. This blocks
# (exit 2) a gh write that merges a pull request other than by rebase, or one that GitHub, asked with
# the credential the command carries, does not answer is such a pull request, unless the command
# carries MERGE_OK=1, set when the maintainer ordered that merge in his own words; silent (exit 0) on
# everything else, and in a project that replaces the merge convention (project.sh). Reads the command
# field of the raw hook input through commands.sh, as stacked-guard.sh does.

input=$(cat)

# a cheap bail on the raw input, which carries the description too; the command itself decides below
case "$input" in
	*"gh api"*merge*|*"gh pr "*|*"gh -"*) ;;
	*) exit 0 ;;
esac

. "$(dirname "$0")/commands.sh"
project_keeps merge "$(input_cwd "$input")" || exit 0

# the marker counts in the command, not in its description
case "$(printf '%s' "$input" | jq -r '.tool_input.command // empty')" in
	*MERGE_OK=1*) exit 0 ;;
esac

cmds=$(commands "$input")
merges=$(gh_writes "$cmds" 'pr merge' '^(https://api\.github\.com)?/?repos/[^/]+/[^/]+/pulls/[0-9]+/merge$')
[ -n "$merges" ] || exit 0

refuse() {
	echo "merge-guard: $1. The session merges only a harness pull request review.js passed (CONVENTIONS.md, \"Patches and commits\"); one the maintainer ordered merged in his own words takes MERGE_OK=1." >&2
	exit 2
}

token=$(gh_token "$input")
github() {
	GH_TOKEN=$token gh api "$@" 2>/dev/null
}

# whether the commit <sha> of the repository <repo> carries the agent-review status
reviewed() {
	[ "$(github "repos/$1/commits/$2/status" --jq '.statuses[] | select(.context == "agent-review") | .state')" = success ]
}

# whether the commit <sha> of the repository <repo> has check runs and passed every one, exiting 2 where
# it has none
passed() {
	local checks
	checks=$(github "repos/$1/commits/$2/check-runs?per_page=100" --jq '.check_runs[] | .conclusion // "pending"') || return 1
	[ -n "$checks" ] || return 2
	! printf '%s\n' "$checks" | grep -vqxE 'success|skipped|neutral'
}

# whether a comment of the account <login> on the pull request <number> of the repository <repo> names
# the head <sha> and holds a line that the ERE after <repo> on a line of $HARNESS_LOCAL_GATES matches
gated() {
	local gate
	gate=$(printf '%s\n' "$HARNESS_LOCAL_GATES" | awk -v repo="$1" '
		NF > 1 && tolower($1) == tolower(repo) { sub(/^[^ \t]+[ \t]+/, ""); print; exit }')
	[ -n "$gate" ] && github "repos/$1/issues/$2/comments?per_page=100" --paginate \
		--jq ".[] | select(.user.login == \"$3\") | .body | select(contains(\"${4:0:9}\"))" |
		grep -qE -- "$gate"
}

# the repository and the commit, "<owner>/<name> <sha>", the pull request of the repository <repo> whose head
# is <head> pins when its one file, <path>, is a submodule; nothing for any other
pinned() {
	local type pin url
	[ "$(printf '%s\n' "$3" | wc -l)" -eq 1 ] || return 0
	IFS=$'\t' read -r type pin url <<< "$(github "repos/$1/contents/$3?ref=$2" --jq '[.type, .sha, .submodule_git_url // ""] | @tsv')"
	[ "$type" = submodule ] || return 0
	url=$(printf '%s' "$url" | sed -E 's#\.git$##; s#/+$##; s#^.*[:/]([^/:]+/[^/:]+)$#\1#')
	case $url in ../*) url=${1%%/*}/${url#../} ;; esac
	printf '%s %s\n' "$url" "$pin"
}

# whether the repository <repo> is the harness's own, by the name its checkout's origin gives
harness=$(project_repo "$(harness_root)" | tr '[:upper:]' '[:lower:]')
own() {
	[ -n "$harness" ] && [ "$(printf '%s' "${1##*/}" | tr '[:upper:]' '[:lower:]')" = "${harness##*/}" ]
}
checks=$(cd "$(dirname "$0")" && pwd)

while IFS= read -r merge; do
	if [ "$(printf '%s' "$merge" | awk '{ print $2 }')" = pr ]; then
		printf '%s\n' "$merge" | grep -Eq -- ' (--rebase|-r)( |$)'
	else
		printf '%s\n' "$merge" | grep -Eq -- ' merge_method=rebase( |$)'
	fi || refuse "a pull request merges by rebase, as the maintainer's do and the merged skill reads them"

	repo=$(gh_repo "$merge")
	repo=${repo:-{owner\}/{repo\}}
	number=$(gh_number "$merge")
	read -r state base author head <<< "$(github "repos/$repo/pulls/$number" --jq '[.state, .base.ref, .user.login, .head.sha] | @tsv')"
	[ -n "$head" ] || refuse "GitHub did not answer for #$number"
	trunk=$(github "repos/$repo" --jq .default_branch)
	[ "$state" = open ] && [ -n "$trunk" ] && [ "$base" = "$trunk" ] || refuse "#$number is not open on the default branch, ${trunk:-which GitHub did not answer}"
	login=$(github user --jq .login)
	[ "$author" = "$login" ] || refuse "#$number was not opened by the posting account"

	paths=$(github "repos/$repo/pulls/$number/files?per_page=100" --paginate --jq '.[] | .filename, .previous_filename // empty')
	[ -n "$paths" ] || refuse "GitHub did not answer for the files of #$number"
	read -r upstream pin <<< "$(pinned "$repo" "$head" "$paths")"
	# a pull request of the harness's own repository, or one that moves a mount of it, is the harness whole;
	# another's paths are read from no checkout, since they are its repository's and not the session's
	if ! own "$repo" && ! own "$upstream"; then
		outside=$(printf '%s\n' "$paths" | (cd / && bash "$checks/harness-mixed.sh" --outside))
		[ -z "$outside" ] || refuse "#$number changes what is not the harness: $(echo $outside)"
	fi

	if [ -n "$pin" ]; then
		trunk=$(github "repos/$upstream" --jq .default_branch)
		case "$(github "repos/$upstream/compare/$trunk...$pin" --jq .status)" in
		identical|behind) ;;
		*) refuse "${pin:0:9}, which #$number pins, is not on the trunk of $upstream" ;;
		esac
		reviewed "$upstream" "$pin" || refuse "${pin:0:9}, which #$number pins, carries no agent-review status"
		passed "$upstream" "$pin" || refuse "the CI of ${pin:0:9}, which #$number pins, has not passed"
	else
		reviewed "$repo" "$head" || GH_TOKEN=$token gh_proved "$repo" "$number" "$login" "$head" ||
			refuse "the head of #$number, ${head:0:9}, carries no agent-review status, nor a proof that names it"
	fi
	passed "$repo" "$head" || { [ $? -eq 2 ] && gated "$repo" "$number" "$login" "$head"; } ||
		refuse "the CI of ${head:0:9} has not passed, nor a local gate HARNESS_LOCAL_GATES names for $repo in a comment that names that head"
	subjects=$(github "repos/$repo/pulls/$number/commits?per_page=100" --paginate --jq '.[].commit.message | split("\n")[0]')
	[ -n "$subjects" ] || refuse "GitHub did not answer for the commits of #$number"
	! printf '%s\n' "$subjects" | grep -qE '^(fixup|amend|squash)! ' ||
		refuse "#$number carries a fixup!, amend! or squash! commit, which folds before the merge"
done <<< "$merges"

exit 0

