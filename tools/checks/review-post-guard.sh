#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# PreToolUse (Bash) hook: a GitHub review, a review body, or a comment on a pull
# request or an issue references a fixup by its full commit URL, since a backtick'd
# SHA renders as code and does not link. This blocks (exit 2) a gh write to
# reviews/comments that carries a backtick'd SHA or whose text fails the checks
# below; silent (exit 0) on everything else. The session posts the text without
# the maintainer's OK on it (AGENTS.md, *Deciding what to change*), so no marker
# stands for one.
# Reads the command field of the raw hook input through commands.sh: the
# description beside it and the commands chained with the post are not the post.
#
# The text of a post is read from the files the command names (body=@<file>,
# --body-file, --input) and run through machine-leak.sh, since a review comment
# is how the machine escaped into GitHub before any file did, and through the
# check that every text, the review body and each inline comment, opens with
# GitHub's note that an LLM wrote it, since the account it posts under is the
# maintainer's. The raw input is not scanned: it carries the working directory
# on every command, so a scan of it would fire on every post. Text the guard
# cannot read, passed inline or on stdin, is refused rather than skipped, and so
# is a comment given to gh's close or reopen, which no file carries.

input=$(cat)

. "$(dirname "$0")/commands.sh"

# a cheap bail on the command's words; the command itself decides below
case "$(command_words "$input")" in
	*"gh api"*reviews*|*"gh api"*comments*|*"gh pr "*|*"gh issue "*|*"gh -"*) ;;
	*) exit 0 ;;
esac

cmds=$(gh_commands "$input")
if gh_writes "$cmds" '(issue|pr) (close|reopen)' '^$' | grep -qE -- ' (-c|--comment)([ =]|$)'; then
	echo "review-post-guard: a comment given to a close or a reopen is text no file carries: post it through the comments endpoint, where this guard reads it, then close." >&2
	exit 2
fi

posts=$(gh_writes "$cmds" 'pr (review|comment)|issue comment' \
	'^(https://api\.github\.com)?/?repos/[^/]+/[^/]+/(pulls|issues)/([0-9]+/)?(reviews|comments)(/|$)')
[ -n "$posts" ] || exit 0

files=
# a private repository's name is a leak wherever a text is published but to that repository
private=
while IFS= read -r post; do
	[ -z "$(gh_private "$post" "$input")" ] || private=$LUNATIK_CONSUMERS
	body=$(gh_body "$post")
	case $body in
	"") ;;
	inline)
		[ "$(printf '%s' "$post" | awk '{ print $2 }')" = api ] && body='-F body=@<file>' || body='--body-file <file>'
		echo "review-post-guard: the text of a post is read from a file: pass it as $body." >&2
		exit 2 ;;
	*)
		files="$files ${body#* }" ;;
	esac
done <<< "$posts"

for f in $files; do
	[ -f "$f" ] && continue
	echo "review-post-guard: the text of a post is read from a file, and $f is not one. The guard reads the command before it runs, so a text the same command writes, by cp, a redirect or a heredoc, is not there yet: write it in a command of its own first. A path written as a shell variable arrives here unexpanded: spell it out." >&2
	exit 2
done

leaked=$(for f in $files; do LUNATIK_CONSUMERS=$private bash "$(dirname "$0")/machine-leak.sh" "$f"; done)
if [ -n "$leaked" ]; then
	echo "review-post-guard: the text carries what belongs to the machine it was written on:" >&2
	echo "$leaked" >&2
	echo "review-post-guard: rewrite the line and re-run." >&2
	exit 2
fi

untraced=$(for f in $files; do bash "$(dirname "$0")/untraced.sh" "$f"; done)
if [ -n "$untraced" ]; then
	echo "review-post-guard: $untraced" >&2
	exit 2
fi

undecided=$(for f in $files; do bash "$(dirname "$0")/decision.sh" "$f"; done)
if [ -n "$undecided" ]; then
	echo "review-post-guard: $undecided" >&2
	exit 2
fi

# the account is the maintainer's, so every text opens with the note, its two lines a GitHub alert
alert='> \[!NOTE\]'
llm='> This [a-z]+ was written by an LLM, not a human\.'
unsigned=$(for f in $files; do
	case "$(head -c 1 "$f")" in
		"{") grep -oE '"body"[[:space:]]*:[[:space:]]*"(\\.|[^"\\]){0,80}' "$f" |
			grep -vE "^\"body\"[[:space:]]*:[[:space:]]*\"$alert"'\\n'"$llm" ;;
		*) head -n 2 "$f" | tr '\n' '\t' | grep -qE "^$alert"$'\t'"$llm"$'\t' || echo "$f: $(head -n 1 "$f")" ;;
	esac
done)
if [ -n "$unsigned" ]; then
	echo "review-post-guard: a text posted under the maintainer's account opens with GitHub's note that an LLM wrote it, \"> [!NOTE]\" and \"> This <review|comment> was written by an LLM, not a human.\" on the next line, the review body and each inline comment alike; these do not:" >&2
	echo "$unsigned" >&2
	exit 2
fi

if printf '%s' "$posts" | grep -Eq '`[0-9a-f]{7,40}'; then
	echo "review-post-guard: a fixup reference is a backtick'd SHA, which GitHub renders as code, not a link. Use a full commit URL: https://github.com/<owner>/<repo>/commit/<sha>" >&2
	exit 2
fi

exit 0

