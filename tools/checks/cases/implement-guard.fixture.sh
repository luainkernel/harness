#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Builds, in the empty directory <dir>, the repository implement-guard.cases reads: a binding and a
# check committed, and a change to the binding staged, so a commit made over it carries code, as the
# code key of its .agents/harness.conf reads lib/ and a lunatik* file at its top.
#
# Usage: bash tools/checks/cases/implement-guard.fixture.sh <dir>

cd "$1" || exit 1
export GIT_AUTHOR_NAME=cases GIT_AUTHOR_EMAIL=cases@example.invalid
export GIT_COMMITTER_NAME=cases GIT_COMMITTER_EMAIL=cases@example.invalid
git init -q -b master . || exit 1
mkdir .agents lib tools
printf 'code=^(lib|common|tests|examples|autogen|bin)/|^lunatik[^/]*$\n' > .agents/harness.conf
printf 'static int luaset_new(lua_State *L)\n{\n\treturn 0;\n}\n' > lib/luaset.c
printf 'exit 0\n' > tools/check.sh
git add lib/luaset.c tools/check.sh && git commit -q -m base || exit 1
printf '/* a change */\n' >> lib/luaset.c
git add lib/luaset.c

