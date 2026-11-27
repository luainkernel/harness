#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Writes, in the empty directory <dir>, what merge-guard.cases reads: a gh on stub/ that answers, only
# with the token in key, that the repository's default branch is master and #7 is a pull request the
# guard merges, opened on master by the posting account, changing one check and the settings that
# wire the guards, its head carrying the agent-review status and passing its one check run, that #8
# is the same pull request with a fixup! on top of its commit, and that #9 is #7 opened on bump. #10,
# #11 and #12 bump the mount, harness, their heads carrying no agent-review status, to a commit of
# luainkernel/harness: #10's on its trunk and carrying the status, #11's on its trunk and carrying none,
# #12's carrying it and not on its trunk. #13 is a pull request of luainkernel/harness that changes its
# README and a license with a check. #14, #15 and #16 change a check, their heads carrying no
# agent-review status: #14 adds 12 lines and a comment of the posting account names its head, #15 adds
# 12 and no comment names it, #16 adds 90 and a comment names it. #17 to #20 change a check and their
# heads have no check run: #17's head carries the agent-review status and a comment names it beside a
# passing gate's line, #18's carries it and the comment that names it holds a failing gate's line,
# #19's carries it and the passing line is in a comment of another account or of another head, and
# #20 adds 12, its head carrying no status, and one comment names it beside the passing line; #21 is #17
# with a failing check run on its head. A filter handed to --jq runs over their comments. Under replaced/, a checkout whose .agents/harness.conf
# replaces the merge convention.
#
# Usage: bash tools/checks/cases/merge-guard.fixture.sh <dir>

cd "$1" || exit 1
printf cases > key
git init -q replaced && mkdir replaced/.agents && printf 'replaces=merge\n' > replaced/.agents/harness.conf || exit 1
mkdir -p stub
cat > stub/gh <<'STUB'
#!/bin/sh
[ "$GH_TOKEN" = cases ] || exit 1
# the comments on stdin through the filter the command hands --jq, as gh prints them
comments() {
	filter="" prev=""
	for arg; do [ "$prev" = --jq ] && filter=$arg; prev=$arg; done
	jq -r "$filter"
}
case "$*" in
	*/issues/17/comments*) printf '%s\n' '[{"user": {"login": "cases"}, "body": "On 171717171:\n\n    gates: pass:2 fail:0"}]' | comments "$@" ;;
	*/issues/18/comments*) printf '%s\n' '[{"user": {"login": "cases"}, "body": "On 181818181:\n\n    gates: pass:1 fail:1"}]' | comments "$@" ;;
	*/issues/19/comments*) printf '%s\n' '[{"user": {"login": "other"}, "body": "On 191919191:\n\n    gates: pass:2 fail:0"},
		{"user": {"login": "cases"}, "body": "On 012345678:\n\n    gates: pass:2 fail:0"},
		{"user": {"login": "cases"}, "body": "On 191919191, the gate to come"}]' | comments "$@" ;;
	*/issues/20/comments*) printf '%s\n' '[{"user": {"login": "cases"}, "body": "The defect before and the case after, on 303030303:\n\n    gates: pass:2 fail:0"}]' | comments "$@" ;;
	*/issues/21/comments*) printf '%s\n' '[{"user": {"login": "cases"}, "body": "On 313131313:\n\n    gates: pass:2 fail:0"}]' | comments "$@" ;;
	*/pulls/17\ *) printf 'open\tmaster\tcases\t1717171717171717171717171717171717171717\n' ;;
	*/pulls/18\ *) printf 'open\tmaster\tcases\t1818181818181818181818181818181818181818\n' ;;
	*/pulls/19\ *) printf 'open\tmaster\tcases\t1919191919191919191919191919191919191919\n' ;;
	*/pulls/20\ -q\ .additions) echo 12 ;;
	*/pulls/20\ *) printf 'open\tmaster\tcases\t3030303030303030303030303030303030303030\n' ;;
	*/pulls/21\ *) printf 'open\tmaster\tcases\t3131313131313131313131313131313131313131\n' ;;
	*/pulls/1[789]/files*|*/pulls/2[01]/files*) echo tools/checks/cases.sh ;;
	*/pulls/1[789]/commits*|*/pulls/2[01]/commits*) echo 'checks: name a case' ;;
	*/commits/3131*/check-runs*) echo failure ;;
	*/commits/1[789]1[789]*/check-runs*|*/commits/3030*/check-runs*|*/commits/3030*/status\ *) ;;
	*/pulls/1[45]\ -q\ .additions) echo 12 ;;
	*/pulls/16\ -q\ .additions) echo 90 ;;
	*/pulls/14\ *) printf 'open\tmaster\tcases\t1414141414141414141414141414141414141414\n' ;;
	*/pulls/15\ *) printf 'open\tmaster\tcases\t1515151515151515151515151515151515151515\n' ;;
	*/pulls/16\ *) printf 'open\tmaster\tcases\t1616161616161616161616161616161616161616\n' ;;
	*/pulls/1[456]/files*) echo tools/checks/cases.sh ;;
	*/pulls/1[456]/commits*) echo 'checks: name a case' ;;
	*/issues/14/comments*) echo 'The defect before and the case after, on 141414141' ;;
	*/issues/15/comments*) echo 'The defect before and the case after' ;;
	*/issues/16/comments*) echo 'The defect before and the case after, on 161616161' ;;
	*/commits/1[456]1[456]*/status\ *) ;;
	*/pulls/[78]\ *) printf 'open\tmaster\tcases\t0123456789abcdef0123456789abcdef01234567\n' ;;
	*/pulls/9\ *) printf 'open\tbump\tcases\t0123456789abcdef0123456789abcdef01234567\n' ;;
	*/pulls/10\ *) printf 'open\tmaster\tcases\t1010101010101010101010101010101010101010\n' ;;
	*/pulls/11\ *) printf 'open\tmaster\tcases\t1111111111111111111111111111111111111111\n' ;;
	*/pulls/12\ *) printf 'open\tmaster\tcases\t1212121212121212121212121212121212121212\n' ;;
	*/pulls/13\ *) printf 'open\tmaster\tcases\t1313131313131313131313131313131313131313\n' ;;
	api\ user\ *) echo cases ;;
	api\ repos/*/*\ --jq\ .default_branch) echo master ;;
	*/pulls/[78]/files*) printf 'tools/checks/cases.sh\n.claude/settings.json\n' ;;
	*/pulls/1[012]/files*) echo harness ;;
	*/pulls/13/files*) printf 'README.md\nLICENSE-MIT\ntools/checks/cases.sh\n' ;;
	*/pulls/7/commits*|*/pulls/1[0-3]/commits*) echo 'checks: name a case' ;;
	*/pulls/8/commits*) printf 'checks: name a case\nfixup! checks: name a case\n' ;;
	*/contents/harness\?ref=1010101010101010101010101010101010101010\ *) printf 'submodule\t2020202020202020202020202020202020202020\thttps://github.com/luainkernel/harness.git\n' ;;
	*/contents/harness\?ref=1111111111111111111111111111111111111111\ *) printf 'submodule\t2121212121212121212121212121212121212121\thttps://github.com/luainkernel/harness.git\n' ;;
	*/contents/harness\?ref=1212121212121212121212121212121212121212\ *) printf 'submodule\t2222222222222222222222222222222222222222\thttps://github.com/luainkernel/harness.git\n' ;;
	*/luainkernel/harness/compare/master...2222222222222222222222222222222222222222\ *) echo ahead ;;
	*/luainkernel/harness/compare/master...*) echo behind ;;
	*/commits/1010101010101010101010101010101010101010/status\ *|*/commits/1111111111111111111111111111111111111111/status\ *|*/commits/1212121212121212121212121212121212121212/status\ *|*/commits/2121212121212121212121212121212121212121/status\ *) ;;
	*/status\ *|*/check-runs*) echo success ;;
	*) exit 1 ;;
esac
STUB
chmod +x stub/gh

