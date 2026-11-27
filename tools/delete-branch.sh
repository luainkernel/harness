#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Deletes the branch <branch> of the repository <owner>/<repo> once a pull request of that repository
# merged from it, and only where its tip is the head that pull request merged with, so no commit pushed
# after the merge goes (the merged skill, section 4); GitHub refuses the default branch's delete itself.
# A branch already gone, as a repository whose delete_branch_on_merge is set leaves it, is reported and
# passes.
# The session runs it under a narrow permissions.allow rule: the auto mode classifier refuses the
# session's own delete of a branch its autoMode rules do not name, where the conversation holds no
# order of the maintainer's.
#
# Usage: bash tools/delete-branch.sh <owner>/<repo> <branch> <file that holds the token>

set -o pipefail

[ $# -eq 3 ] && [[ $1 =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ && $2 =~ ^[A-Za-z0-9_.+/-]+$ ]] ||
	{ echo "usage: $0 <owner>/<repo> <branch> <token file>" >&2; exit 2; }

GH_TOKEN=$(cat "$3" 2> /dev/null)
export GH_TOKEN
repo=$1 branch=$2

tip=$(gh api --paginate "repos/$repo/git/matching-refs/heads/$branch" |
	jq -r --arg ref "refs/heads/$branch" '.[] | select(.ref == $ref) | .object.sha') || exit 1
[ -n "$tip" ] || { echo "delete-branch: $repo has no branch $branch"; exit 0; }

pr=$(gh api -X GET "repos/$repo/pulls" -f head="${repo%%/*}:$branch" -f state=closed -f per_page=100 |
	jq -r --arg repo "$repo" --arg branch "$branch" --arg tip "$tip" 'first(.[] | select(.merged_at != null and
		.head.repo.full_name == $repo and .head.ref == $branch and .head.sha == $tip) | .number)') || exit 1
[ -n "$pr" ] || { echo "delete-branch: no merged pull request of $repo has $branch at $tip as its head" >&2; exit 1; }

# the lease has GitHub refuse the delete once the branch moved past the tip the checks above read
git -C "$(dirname "$(readlink -f "$0")")" -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
	push -q --force-with-lease="refs/heads/$branch:$tip" "https://github.com/$repo.git" ":refs/heads/$branch" || exit 1
echo "delete-branch: $repo $branch deleted at $tip, the head #$pr merged with"

