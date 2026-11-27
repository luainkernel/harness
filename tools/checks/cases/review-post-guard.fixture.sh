#!/bin/bash
#
# SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
# SPDX-License-Identifier: MIT OR GPL-2.0-only
#
# Writes, in the empty directory <dir>, a checkout whose origin is luainkernel/lunatik and the texts
# review-post-guard.cases posts: a comment and a review
# that open with the note, one with the note at its end, as an issue filed elsewhere carries it, one with
# the line the note replaced, a review whose inline comment lacks the note, and under sub/, read only
# after a cd into it, the comment that opens with the note; beside them a gh on stub/ that answers
# nothing; under vault/, a clone of a private
# repository, acme/vault, and a comment that opens with the note and names it, there and beside it.
#
# Usage: bash tools/checks/cases/review-post-guard.fixture.sh <dir>

cd "$1" || exit 1
git init -q . && git remote add origin https://github.com/luainkernel/lunatik.git || exit 1
note='> [!NOTE]
> This comment was written by an LLM, not a human.'
printf '%s\n\nThe callback returns the queue and the slice.\n' "$note" > note.md
printf 'The callback returns the queue and the slice.\n\n%s\n' "$note" > late.md
printf '(posted by an agent, not by @lneto)\n\nThe callback returns the queue and the slice.\n' > line.md
mkdir -p sub
cp note.md sub/post.md
git init -q vault && git -C vault remote add origin https://github.com/acme/vault.git || exit 1
printf '%s\n\nThe vault loader calls the callback.\n' "$note" > vault.md
cp vault.md vault/vault.md

review=$(printf '%s\n\n@author, requesting changes.' "${note/comment/review}")
comment=$(cat note.md)
jq -n --arg body "$review" --arg comment "$comment" \
	'{event: "COMMENT", body: $body, comments: [{path: "a.c", line: 1, side: "RIGHT", body: $comment}]}' > review.json
jq -n --arg body "$review" \
	'{event: "COMMENT", body: $body, comments: [{path: "a.c", line: 1, side: "RIGHT", body: "The callback returns."}]}' \
	> bare.json

mkdir -p stub
printf '#!/bin/sh\nexit 1\n' > stub/gh
chmod +x stub/gh

