#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Measures where the tokens go, from the transcripts and the run records Claude Code keeps for the
# sessions started in the directory it runs in: by kind of run, by role, model and effort, the first
# request of each agent type, the requests that wrote the cache again with what each waited on, and the
# pull requests the runs opened. It prints sums and counts, never a transcript's text. Claude Code writes
# a request's usage on every line of its answer, so a request counts once, by its id, and its output is
# the most a line of it carries: a line written before the answer ended can carry less. A request past a
# transcript's first that writes more than half of a context over 20k tokens is a rewrite, read by the time
# between its send and the one before it: under five minutes, past them a notification or a prompt that
# woke it, a send repeated after no answer, or the turn before it or the tool call after that running past
# five minutes. Claude Code keeps a transcript 30 days by default, its cleanupPeriodDays.
#
# Usage: bash tools/usage.sh [--since <date>] [--until <date>]   (a window, default all it keeps)
#        bash tools/usage.sh <run id>...                          (these runs, a line each first)

since=1970-01-01T00:00:00
until=9999-12-31T23:59:59
runs=()
while [ $# -gt 0 ]; do
	case $1 in
		--since|--until)
			at=$([ -n "${2-}" ] && date -u -d "$2" +%FT%T 2> /dev/null) || { echo "usage.sh: $1 takes a date" >&2; exit 2; }
			if [ "$1" = --since ]; then since=$at; else until=$at; fi
			shift 2 ;;
		wf_*) runs+=("$1"); shift ;;
		*) echo "usage: $0 [--since <date>] [--until <date>] [<run id>...]" >&2; exit 2 ;;
	esac
done

projects=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/$(pwd -P | sed 's/[^A-Za-z0-9]/-/g')
[ -d "$projects" ] || { echo "usage.sh: Claude Code keeps no session started in $(pwd -P)" >&2; exit 2; }

shopt -s nullglob
files=("$projects"/*/subagents/agent-*.meta.json "$projects"/*/subagents/workflows/*/agent-*.meta.json
	"$projects"/*/workflows/wf_*.json)
if [ ${#runs[@]} -eq 0 ]; then
	files+=("$projects"/*.jsonl "$projects"/*/subagents/agent-*.jsonl "$projects"/*/subagents/workflows/*/agent-*.jsonl)
fi
for run in "${runs[@]}"; do
	agents=("$projects"/*/subagents/workflows/"$run"/agent-*.jsonl)
	[ ${#agents[@]} -gt 0 ] || { echo "usage.sh: no transcript of $run" >&2; exit 2; }
	files+=("${agents[@]}")
done

# jq -R joins a last line with no newline, every .json's and a live .jsonl's, to the next file's first: awk ends it
printf '%s\0' "${files[@]}" | xargs -0 awk 'FNR == 1 { print "\036" FILENAME } 1' | jq -rR '
	if startswith("\u001e") then ["F", .[1:]]
	else fromjson? |
		if .type == null and .agentType then ["M", .agentType, (.description // "-" | sub(":.*"; ""))]
		elif .type == null and .runId then ["R", .runId, (.workflowName // "-"), (.status // "-"),
			(.startTime // 0), (.args.github? // "-"), ((.result | objects | .pr | numbers) // 0)]
		elif .timestamp == null then empty
		elif .type == "assistant" then
			.message.usage as $u | select($u) |
			["A", .timestamp, (.requestId // .message.id), .message.model, (.effort // "-"), ($u.input_tokens // 0),
			 ($u.cache_creation_input_tokens // 0), ($u.cache_read_input_tokens // 0), ($u.output_tokens // 0)]
		elif .type == "api-request" then ["S", .timestamp]
		elif .type == "user" then ["U", .timestamp,
			if .origin.kind == "human" then "prompt" elif .origin.kind == "task-notification" then "notification"
			elif (.message.content | type) == "array" and any(.message.content[]; .type? == "tool_result") then "result"
			else "other" end]
		else empty end
	end | @tsv' | gawk -v since="$since" -v until="$until" -v only="${runs[*]}" '
BEGIN { FS = OFS = "\t"; PROCINFO["sorted_in"] = "@val_num_desc" }

function epoch(t,  a) {
	split(t, a, /[-T:.Z]/)
	return mktime(a[1] " " a[2] " " a[3] " " a[4] " " a[5] " " a[6], 1) + ("0." a[7])
}

function kindof(run) {
	if (!(run in workflow)) return "runs with no record"
	return workflow[run] ~ /^(implement-issue|review-pr)$/ ? workflow[run] : "other workflows"
}

function open(path,  p, n) {
	file = path; n = split(path, p, "/")
	run = p[n - 2] == "workflows" ? p[n - 1] : "-"
	kind = run != "-" ? kindof(run) : p[n - 1] == "subagents" ? "Agent tool" : "sessions"
	who = kind == "sessions" ? "session" : path in type ? type[path] : "-"
	what = kind == "Agent tool" ? who : path in role ? role[path] : "-"
	split("", row); split("", written); psend = last = lastu = ukind = lasts = ""; tries = requests = 0
}

function wait(  d, gen, tool, entry, gap) {
	if (lasts == "" || psend == "") return "-\tno send recorded"
	d = epoch(lasts) - epoch(psend); gen = epoch(last) - epoch(psend)
	tool = lastu == "" ? 0 : epoch(lastu) - epoch(last); entry = lastu == "" ? 0 : epoch(lasts) - epoch(lastu)
	gap = (d < 300 ? "<5m" : d < 3600 ? "5m-1h" : ">1h") "\t"
	if (d < 300) return gap "under 5 minutes between sends"
	if (ukind == "notification") return gap "woken by a task notification"
	if (ukind == "prompt") return gap "a prompt after the session sat idle"
	if (entry >= gen && entry >= tool)
		return gap (tries > 1 ? "sent again after no answer" : "the send waited after its entry")
	return gap (gen >= tool ? "the turn before ran past 5 minutes" : "the tool call ran past 5 minutes")
}

function request(t, model, effort, in_, cw, cr,  ctx, r, w) {
	ctx = in_ + cw + cr
	if (t >= since && t < until) {
		N[kind]++; IN[kind] += in_; CW[kind] += cw; CR[kind] += cr; ALL[kind] += ctx
		r = kind "\t" what "\t" model "\t" effort
		RN[r]++; RCW[r] += cw; RCR[r] += cr; RCTX[r] += ctx; RALL[r] += ctx
		if (!((r, file) in RA)) { RA[r, file]; RAG[r]++ }
		if (run != "-") {
			QN[run]++; QIN[run] += in_; QCW[run] += cw; QCR[run] += cr
			if (!((run, file) in QA)) { QA[run, file]; QAG[run]++ }
		}
		if (!requests) { FN[who]++; FCTX[who] += ctx; FCW[who] += cw; FCR[who] += cr; FZ[who] += !cr }
		else if (ctx > 20000 && cw > ctx / 2) { w = who "\t" wait(); WN[w]++; WT[w] += cw }
	}
	requests++; psend = lasts
	return r
}

function output(r, more) {
	if (r == "") return
	OUT[kind] += more; ALL[kind] += more; ROUT[r] += more; RALL[r] += more
	if (run != "-") QOUT[run] += more
}

$1 == "F" { path = $2; if (path ~ /\.jsonl$/) open(path); next }
$1 == "M" { sub(/\.meta\.json$/, ".jsonl", path); type[path] = $2; role[path] = $3; next }
$1 == "R" { workflow[$2] = $3; status[$2] = $4; started[$2] = $5; repo[$2] = $6; pr[$2] = $7; next }
$1 == "U" { lastu = $2; ukind = $3; tries = 0; next }
$1 == "S" { if (lasts == "" || epoch($2) - epoch(lasts) > 1) tries++; lasts = $2; next }
$1 == "A" && $4 != "<synthetic>" {
	if (!($3 in row)) row[$3] = request($2, $4, $5, $6, $7, $8)
	if ($9 > written[$3]) { output(row[$3], $9 - written[$3]); written[$3] = $9 }
	last = $2
}

END {
	from = epoch(since) * 1000; to = epoch(until) * 1000
	for (q in workflow) {
		if (only != "" ? !index(" " only " ", " " q " ") : started[q] < from || started[q] >= to)
			continue
		k = kindof(q); RUNS[k]++; DONE[k] += status[q] == "completed"
		if (pr[q] > 0) { OPENED[k]++; PRS[repo[q]] = PRS[repo[q]] " #" pr[q] }
	}
	n = split(only, list, " ")
	for (i = 1; i <= n; i++) {
		q = list[i]
		printf "%s %s %s: %d agents, %d requests, input %d, cache write %d, cache read %d, output %d, %s\n", q,
			q in workflow ? workflow[q] : "-", q in status ? status[q] : "running", QAG[q], QN[q], QIN[q], QCW[q],
			QCR[q], QOUT[q], (pr[q] > 0 ? "pull request " (repo[q] == "-" ? "" : repo[q]) "#" pr[q] : "no pull request")
	}
	for (k in ALL) total += ALL[k]
	printf "\nfrom %s to %s UTC\n%-20s %9s %10s %12s %14s %11s %14s %6s\n", since, until, "kind", "requests",
		"input", "cache write", "cache read", "output", "all tokens", "share"
	for (k in ALL)
		printf "%-20s %9d %10d %12d %14d %11d %14d %5.1f%%\n", k, N[k], IN[k], CW[k], CR[k], OUT[k], ALL[k],
			100 * ALL[k] / total
	printf "\n%-20s %-10s %-10s %-7s %6s %9s %12s %14s %11s %9s\n", "kind", "role", "model", "effort", "agents",
		"requests", "cache write", "cache read", "output", "mean ctx"
	for (r in RALL) {
		split(r, z, "\t"); sub(/^claude-/, "", z[3])
		printf "%-20s %-10s %-10s %-7s %6d %9d %12d %14d %11d %9.0f\n", z[1], z[2], z[3], z[4], RAG[r], RN[r], RCW[r],
			RCR[r], ROUT[r], RCTX[r] / RN[r]
	}
	printf "\nfirst request\n%-20s %6s %10s %12s %11s %13s\n", "agent type", "agents", "mean ctx", "cache write",
		"cache read", "read nothing"
	for (w in FN)
		printf "%-20s %6d %10.0f %12.0f %11.0f %13d\n", w, FN[w], FCTX[w] / FN[w], FCW[w] / FN[w], FCR[w] / FN[w], FZ[w]
	printf "\nrewrites\n%-20s %-6s %-35s %8s %14s\n", "agent type", "gap", "waited on", "requests", "tokens written"
	for (w in WT) {
		split(w, z, "\t")
		printf "%-20s %-6s %-35s %8d %14d\n", z[1], z[2], z[3], WN[w], WT[w]
	}
	printf "\nruns started\n%-20s %6s %10s %15s\n", "kind", "runs", "completed", "a pull request"
	for (k in RUNS)
		printf "%-20s %6d %10d %15d\n", k, RUNS[k], DONE[k], OPENED[k]
	PROCINFO["sorted_in"] = "@ind_str_asc"
	for (k in PRS)
		print "pull requests in " (k == "-" ? "a repository the run did not name" : k) ":" PRS[k]
}'

