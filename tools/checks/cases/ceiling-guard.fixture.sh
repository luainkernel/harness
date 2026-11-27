#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Builds, in the empty directory <dir>, the transcripts ceiling-guard.cases reads: a session's, s.jsonl,
# and beside it under s/subagents/workflows/wf_1/ three agents' a workflow relayed a request to before
# the prompt, past, whose prompt sets a ceiling of 250000 tokens and whose last request carried 260000,
# under, whose prompt sets the same and whose last request carried 100000, and unset, whose prompt sets
# none and whose last request carried 400000.
#
# Usage: bash tools/checks/cases/ceiling-guard.fixture.sh <dir>

dir=$1
run=$dir/s/subagents/workflows/wf_1
mkdir -p "$run" || exit 1
printf '{"type":"user","message":{"role":"user","content":"go"}}\n' > "$dir/s.jsonl"
agent() {
	{
		jq -nc '{type: "user", message: {role: "user", content: "[Workflow harness] the request"}}'
		jq -nc --arg prompt "$2" '{type: "user", message: {role: "user", content: $prompt}}'
		jq -nc --argjson context "$3" '{type: "assistant", message: {model: "claude-opus-5-5",
			usage: {input_tokens: 10, cache_creation_input_tokens: 990, cache_read_input_tokens: ($context - 1000)}}}'
	} > "$run/agent-$1.jsonl"
}
ceiling=$'  You implement an issue.\n  CONTEXT CEILING: 250000 tokens, checkpoint /scratch/issue-h-6/IMPLEMENT.md\n  Past that context...'
agent past "$ceiling" 260000
agent under "$ceiling" 100000
agent unset $'  You implement an issue.\n  CHECKPOINT: /scratch/issue-h-6/IMPLEMENT.md' 400000

