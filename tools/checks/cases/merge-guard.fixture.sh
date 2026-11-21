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
# README and a license with a check.
#
# Usage: bash tools/checks/cases/merge-guard.fixture.sh <dir>

cd "$1" || exit 1
printf cases > key
mkdir -p stub
cat > stub/gh <<'STUB'
#!/bin/sh
[ "$GH_TOKEN" = cases ] || exit 1
case "$*" in
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

