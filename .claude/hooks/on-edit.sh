#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# PostToolUse (Write|Edit) adapter: run the tools/checks file checks over the
# edited file, the harness's and those the edit key of the project's
# .agents/harness.conf names under its own tools/checks, and hand their findings
# back through the hook protocol, so the model is nudged at edit time. The checks
# are plain path-taking scripts (.agents/rules/checks.md); this wrapper only translates.

input=$(cat)
file=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
[ -n "$file" ] && [ -f "$file" ] || exit 0

. "$(dirname "$(readlink -f "$0")")/../../tools/checks/project.sh"

# the checks of the tree the file belongs to, which in a worktree is not the session's: the harness's
# under the tree's mount, or the ones beside this hook where the tree holds its mount empty, as a
# worktree added without its submodules does, or at its top in a tree older than the mount or in the
# harness itself
dir=$(git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null)
[ -n "$dir" ] || exit 0
mount=$(project_mount)
shared=$dir/tools/checks
if [ -n "$mount" ] && [ -d "$dir/$mount" ]; then
	shared=$dir/$mount/tools/checks
	[ -d "$shared" ] || shared=$(harness_root)/tools/checks
fi
[ -d "$shared" ] || exit 0
own=$dir/tools/checks
# an ignored file reaches no commit, and CLAUDE.local.md, one, is where a machine's paths and credentials belong
git -C "$dir" check-ignore -q "$file" && exit 0

# a tree older than a check lacks it, and runs the checks it has
findings=$(for check in machine-leak comment-style comment-siblings lua-style luals inline-code; do
	[ -f "$shared/$check.sh" ] && bash "$shared/$check.sh" "$file" 2>&1
done
for check in $(project_conf edit "$dir"); do
	[ -f "$own/$check.sh" ] && bash "$own/$check.sh" "$file" 2>&1
done)

# a tracked file carries what earlier edits left; nudge only on the lines this one added
rel=$(git -C "$dir" ls-files --error-unmatch --full-name "$file" 2>/dev/null) && {
	added=$(git -C "$dir" diff -U0 HEAD -- "$rel" | awk '/^@@/ { split($3, h, /[+,]/); n = (h[3] == "" ? 1 : h[3]); for (i = 0; i < n; i++) print h[2] + i }')
	findings=$(printf '%s\n' "$findings" | awk -v added="$added" -v f="$file" '
		BEGIN { split(added, a, "\n"); for (i in a) if (a[i] != "") ok[a[i]] = 1 }
		{ if (match($0, "^" f ":[0-9]+:")) { split($0, p, ":"); if (!(p[2] in ok)) next } print }')
}
[ -z "$findings" ] && exit 0

escaped=$(printf '%s' "$findings" | tr '"\t' "' " | sed ':a;N;$!ba;s/\n/\\n/g')
printf '{"decision":"block","reason":"%s"}\n' "$escaped"
exit 0

