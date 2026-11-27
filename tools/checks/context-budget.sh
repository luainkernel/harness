#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Holds the AGENTS.md at the top of the checkout, as the index holds it, to a ceiling of bytes, and in
# the harness's own checkout its CONVENTIONS.md too, which a project imports beside it: every session
# and every workflow agent that loads CLAUDE.md loads them before its first turn (luainkernel/harness#6,
# D172 D). The harness's ceilings are the line below, and a project's the budget key of its
# .agents/harness.conf (project.sh); a project that names none is not read. A pull request that moves
# a ceiling says why.
# Prints what fails and exits 1, silent otherwise.
# Usage: bash tools/checks/context-budget.sh

. "$(dirname "$(readlink -f "$0")")/project.sh"

if [ "$(git rev-parse --show-toplevel 2> /dev/null)" -ef "$(harness_root)" ]; then
	ceilings="AGENTS.md=34943 CONVENTIONS.md=7025"
else
	budget=$(project_conf budget)
	ceilings=${budget:+AGENTS.md=$budget}
fi

status=0
for entry in $ceilings; do
	file=${entry%=*} ceiling=${entry#*=}
	size=$(git show ":$file" 2> /dev/null | wc -c)
	[ "$size" -le "$ceiling" ] && continue
	echo "$file: $size bytes, past its ceiling of $ceiling; a lesson that needs room moves an older passage to the check, the skill or the path rule that holds its subject"
	status=1
done
exit $status

