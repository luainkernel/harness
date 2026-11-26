#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Names a session's transcript whose last request carried more than 300k tokens of context, what the
# request read from the cache, wrote to it and took uncached: every request past that carries all of
# it again, and a thread cleared at a boundary carries none. A compaction's boundary stands for the
# request it replaced, with the context the compaction left, and a message Claude Code wrote itself,
# `<synthetic>`, made no request. Prints that context in tokens, nothing otherwise.
#
# Usage: bash tools/checks/context.sh <transcript>

LIMIT=300000

[ -f "$1" ] || exit 0
tail -n 200 "$1" | jq -Rn --argjson limit "$LIMIT" '[inputs | fromjson? |
	if .type == "system" and .subtype == "compact_boundary" then .compactMetadata.postTokens
	elif .type == "assistant" and .message.model != "<synthetic>" then
		.message.usage | .input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens
	else empty end] | last // 0 | select(. > $limit)'
exit 0

