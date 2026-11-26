---
name: merged
description: After a pull request merges, the maintainer's or a harness one the session merged once an agent's review passed it, retarget the pull requests stacked on its branch to the default branch, restack them onto it, delete the merged branch, open the bump of each project's mount after a merge of the harness, retire the memory's notes the merge settled, and report the queue and the issues the merge closed. Use when told a pull request was merged, to merge a harness pull request review.js returned ready, or to merge one the maintainer approved in his own words.
---

AGENTS.md, "Patches and commits", and the review-pr skill's process.md, "Comments and the verdict", are the authority; this card orders
the steps. A merge reported by the maintainer is taken as given.

# 0. Merge a harness pull request

A harness pull request the session opened merges without the maintainer (AGENTS.md, "Patches and
commits") once `review.js`, the review-pr skill's workflow, ran over it at `high` and returned it
ready, its fixups folded and pushed, and the CI passed on the head that carries them. The review's
pass goes on that head as a commit status, and the merge names the head, so a push after either is
refused, by `merge-guard.sh` and by GitHub:

    bash tools/agent-review.sh <owner>/<repo> <head> <file that holds the token>
    gh api -X PUT repos/<owner>/<repo>/pulls/<N>/merge -f merge_method=rebase -f sha=<head>

`tools/agent-review.sh` sets the status only on the review's own record, the newest reviewer at `high`
effort or above of a tip whose tree is the head's, when it returned ready, so a fold, which moves the
head and not the tree, keeps it, and a later review that returns it not ready withdraws it. It runs as a command of its own, spelled as the `permissions.allow` rule that
allows it spells it, with no `GH_TOKEN=` before it, which no rule matches past:
the auto mode classifier refuses the session's own write of the status where the conversation holds
no order of the maintainer's, as after a `/clear`. One that
`tools/complexity.sh <N> <owner>/<repo>` calls small merges on a proof in place of the review: a
comment on it, opened by GitHub's note that an LLM wrote it, naming its head beside the command that
shows the defect before, its result after and the case still refused, or, for text no command reads,
the passage it replaces beside the new one, and the merge names that head. What the review left as
issues is filed before the merge, as implement-issue's last stage files it. A pull request the
maintainer orders merged in his own words takes `MERGE_OK=1`. The steps below follow either merge,
and the report reaches him as it does for his own.

A pull request the maintainer approved in his own words merges the same way, `MERGE_OK=1` on the
merge in place of the review's status: its fixups folded, with `git rebase -i --autosquash`, into a
head whose tree is the one he read, waiting for no CI and running no suite. The steps below then
run as after any merge.

# 1. Read the merge

    git fetch <url> +refs/heads/master:refs/remotes/origin/master
    gh api repos/<owner>/<repo>/pulls/<N> --jq '[.merged_at, .head.ref, .head.sha] | @tsv'

The pull request merges by rebase: its commits land on master with new SHAs, and every branch
stacked on it still carries the old ones. The recorded `head.sha` is the old tip, the base every
restack below starts from. The checkout sessions start in follows the new master, with
`git merge --ff-only origin/master` there when it has no commit of its own and nothing tracked
changed; `checkout-behind.sh` names it at the next session's start when it does not.

# 2. Retarget first

    gh api "repos/<owner>/<repo>/pulls?base=<head.ref>&state=open" --jq '.[].number'
    gh api -X PATCH repos/<owner>/<repo>/pulls/<M> -f base=master --jq .base.ref

Each pull request based on the merged branch moves to master before anything else touches it.
Left on the merged branch it merges into that branch and never reaches master, which is what #1041
did one merge after #1040; and a merged branch deleted before its stacked pull requests move closes
them.

A stacked pull request opens as a draft, which GitHub does not merge; on master it is marked
ready, through GraphQL since REST has no endpoint for it:

    gh api graphql -f query='mutation($id: ID!) { markPullRequestReadyForReview(input: {pullRequestId: $id}) { pullRequest { isDraft } } }' \
        -f id="$(gh api repos/<owner>/<repo>/pulls/<M> --jq .node_id)"

# 3. Restack

In a worktree of the stacked branch, record its head, then:

    git rebase --onto origin/master <old tip of the merged branch>

The base is the recorded old tip, never `<branch>^`, which points inside a branch that carries
fixups and drops what lies below it. A chain moves in order, each branch onto its predecessor's new
head, with every old head recorded before the first rebase. A conflict stops the chain: it is
resolved hunk by hunk, never with a whole file's `--ours` or `--theirs`, and `git status` shows no
rebase in progress before anything is pushed.

Each moved branch keeps its own change: `git diff <old tip>..<old head> | git patch-id` equals
`git diff origin/master..<new head> | git patch-id`, or the difference is what master changed under
it, said in the report. Then, a command of its own:

    git push <url> <new head>:refs/heads/<branch> --force-with-lease=refs/heads/<branch>:<old head>

Both SHAs are read, never typed: the old head from `git ls-remote <url> refs/heads/<branch>` and the
new one from `git rev-parse HEAD`. A full SHA completed from its short form by hand named no commit
and failed the lease in the restack under #1879.

The report names the ref it moved and, apart, what it was rebased onto.

The body of each moved pull request is read again: a sentence that names the merged base as the one it
stacks on now names a dependency already on master, which a reviewer reads as still pending, so it goes
or says the base is in, through `gh api -X PATCH repos/<owner>/<repo>/pulls/<M> -F body=@<file>`, and the
report says the body was edited. #2119 and #2129 kept their "stacks on #N" after the retargets of
2026-10-23.

# 4. Delete the merged branch

Once no open pull request is based on it, the merged branch goes, from this repository and from the
checkout, unless a worktree holds it checked out:

    git push <url> --delete <head.ref>
    git branch -D <head.ref>

Its commits are on master under new SHAs, and GitHub keeps the old head as `refs/pull/<N>/head`. A
delete the session's permissions refuse goes to the maintainer as a script under `/tmp` and the line
that runs it (AGENTS.md, *Deciding what to change*).

# 5. The bumps a harness merge opens

A pull request of the harness's own repository reaches a project only through the commit its mount
points at. Once one merges, its `agent-review` status goes on the commit the merge put on the harness's
trunk, the `sha` the merge answered: the rebase gave the reviewed head a new SHA, and a bump is read on
that one. A small one merged on its proof takes the status too, its description naming the proof.
`tools/agent-review.sh` reads which of the two the merged pull request was, through the record of the
review of its head or the comment that proves it, and refuses a commit that merged on neither:

    bash tools/agent-review.sh <owner>/<harness> <merged commit> <file that holds the token>

Each project that mounts the harness then takes a pull request of its own that moves the mount to the
merged commit, its trunk's tip, and nothing else, a harness pull request of that project:

    git -C <project checkout>/<mount> fetch origin && git -C <project checkout>/<mount> checkout <merged commit>
    git -C <project checkout> add <mount>

The bump merges as section 0 merges a harness pull request, on the project's CI, which runs the shared
checks from the new mount over it, and on the review and the CI of the commit it pins (luainkernel/lunatik#2598,
D102 B): `merge-guard.sh` reads that commit on the harness's trunk, carrying the `agent-review` status and
passing the check runs its push to the trunk started, and asks no status of the bump's own head.

# 6. Retire the memory's notes

The session's Claude Code memory, `~/.claude/projects/<project>/memory/`, keeps what the tree does not
hold yet, and its index, `MEMORY.md`, loads in every session and every workflow agent, which is why
`memory-guard.sh` holds it to 8192 bytes. A note of type `feedback` is a lesson on its way to the tree:
each one that names a file the merged pull request changed is read against that file on master, and one
whose lesson the file now holds is deleted, its line taken out of the index. A note of type `project` is
work in flight: one that names an issue or the pull request the merge closed, and whose work is done
with it, is archived, its line moved from the index to `project_archive.md`, the note the index links
for them, and so is every other `project` note whose cited issues and pull requests are all closed,
whatever closed them. Notes of type `user` and `reference` stay.

    gh api --paginate repos/<owner>/<repo>/pulls/<N>/files --jq '.[].filename'
    grep -lF -e <file> -e '#<N>' -e '#<closed issue>' <memory>/*.md
    gh api repos/<owner>/<repo>/issues/<n> --jq .state    # each number a project note cites

The index is edited with Edit, which the guard measures; a shell write into it is refused.

# 7. Report

The new master tip; for each stacked pull request, retargeted, restacked, the patch verdict and the
push; the branches deleted, and a branch a worktree kept with whose it is; `bash tools/pr-status.sh`
for the queue that follows; the issues the merge closed, with any it names only as "Part of" that
it finished; the memory's notes retired and archived; and, after a merge of the harness, each
project's bump with its number.

