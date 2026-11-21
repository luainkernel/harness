#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Builds, in the empty directory <dir>, what stacked-guard.cases reads: the JSON gh api sends for a create
# of stacked on bump, the same asking for a draft, the same on master, and a move onto bump; under sub/,
# read only after a cd into it, the create on bump twice, once named as the one on master; beside them
# a gh on stub/ that answers GitHub's pulls/9 is not a draft and pulls/8 is one, in luainkernel/lunatik or
# the checkout's repository alone, and that the default branch of luainkernel/lunatik is master and that
# of luainkernel/sibling main, and one on keyed/ that answers as it only with the token in key; under
# trunk/, a checkout of luainkernel/sibling whose origin's HEAD names main.
#
# Usage: bash tools/checks/cases/stacked-guard.fixture.sh <dir>

cd "$1" || exit 1
mkdir -p stub sub
jq -n '{head: "stacked", base: "bump", body: "A fifo."}' > stacked.json
jq -n '{head: "stacked", base: "bump", draft: true, body: "A fifo."}' > draft.json
jq -n '{head: "stacked", base: "master", body: "A fifo."}' > master.json
jq -n '{base: "bump"}' > move.json
cp stacked.json sub/s.json
cp stacked.json sub/master.json
git init -q trunk && git -C trunk remote add origin https://github.com/luainkernel/sibling.git &&
	git -C trunk symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main || exit 1
cat > stub/gh <<'STUB'
#!/bin/sh
case "$*" in
	*pulls/9\ *) echo false ;;
	*/luainkernel/lunatik/pulls/8\ *|*/{owner}/{repo}/pulls/8\ *) echo true ;;
	*"repos/luainkernel/lunatik --jq .default_branch") echo master ;;
	*"repos/luainkernel/sibling --jq .default_branch") echo main ;;
	*) exit 1 ;;
esac
STUB
chmod +x stub/gh

printf cases > key
mkdir -p keyed
cat > keyed/gh <<STUB
#!/bin/sh
[ "\$GH_TOKEN" = cases ] && exec "$PWD/stub/gh" "\$@"
exit 1
STUB
chmod +x keyed/gh

