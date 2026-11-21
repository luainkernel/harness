#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# SessionStart hook: the checkout a session starts in is where that session and every agent it
# launches read AGENTS.md, the skills and the guards, so one left behind its trunk works to rules
# the trunk has changed. Takes the checkout, default the current directory, and prints one line when
# its HEAD is behind origin's trunk (project_trunk): how far, and the fast-forward that brings it
# level, which is run only on a checkout with no commit of its own and nothing tracked changed. A
# fast-forward moves the commit the harness's mount points at and not the files under it, so it prints
# one line too when the mount holds another commit than HEAD points at, and the update that checks it
# out. Silent otherwise. It fetches nothing: the remote-tracking ref is shared by every worktree, and
# any session's fetch moves it.

. "$(dirname "$(readlink -f "$0")")/project.sh"

top=$(git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null) || exit 0
trunk=$(project_trunk "$top")
upstream=refs/remotes/origin/$trunk
mount=$(project_mount)
update=${mount:+ && git -C $top submodule update --init $mount}

if [ -n "$mount" ]; then
	pinned=$(git -C "$top" rev-parse -q --verify "HEAD:$mount" 2>/dev/null)
	checked=
	[ -e "$top/$mount/.git" ] && checked=$(git -C "$top/$mount" rev-parse -q --verify HEAD 2>/dev/null)
	short=${checked:0:9}
	[ -z "$pinned" ] || [ "$pinned" = "$checked" ] ||
		echo "checkout-behind: $top/$mount holds ${short:-no checkout}, and HEAD points the mount at ${pinned:0:9}; git -C $top submodule update --init $mount checks it out"
fi

git -C "$top" rev-parse -q --verify "$upstream^{commit}" >/dev/null || exit 0

count() {
	[ "$1" -eq 1 ] && echo "1 $2" || echo "$1 $3"
}

behind=$(git -C "$top" rev-list --count "HEAD..$upstream" 2>/dev/null)
[ "${behind:-0}" -gt 0 ] || exit 0

own=$(git -C "$top" rev-list --count "$upstream..HEAD")
# a status that refreshes the index takes the lock another session's git in this checkout needs
changed=$(GIT_OPTIONAL_LOCKS=0 git -C "$top" status --porcelain --untracked-files=no -- . ${mount:+":!$mount"} | wc -l)
held=""
[ "$own" -gt 0 ] && held="$(count "$own" commit commits) of its own"
[ "$changed" -gt 0 ] && held="${held:+$held and }$(count "$changed" "tracked file" "tracked files") changed"

level="git -C $top merge --ff-only origin/$trunk$update"
if [ -z "$held" ]; then
	echo "checkout-behind: $top is $(count "$behind" commit commits) behind origin/$trunk; $level brings it level"
else
	echo "checkout-behind: $top is $(count "$behind" commit commits) behind origin/$trunk and has $held; $level brings it level once it has neither"
fi

