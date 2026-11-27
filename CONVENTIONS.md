# Conventions of Lunatik and luaebpf

The conventions Lunatik, luaebpf and this repository keep beside the rules of `AGENTS.md`: what
keeps a mechanism past the small shape, how a decision reaches the maintainer, how a commit is
titled, what a pull request carries, which pull requests the session merges, the header a file opens
with and the blank line it ends with. A project that mounts the harness imports this file beside
`AGENTS.md` or keeps conventions of its own in their place, and the `replaces` key of its
`.agents/harness.conf` names those of this file it keeps its own in place of, whose checks the shared
scripts skip there, `title`, `decision`, `merge`, `license` and `blank`, and whose steps the shared
workflows drop, `smallest`, `complexity` and `mechanism`, which each launch passes as the key spells
them (`tools/checks/project.sh`); one that names none, the harness's own checkout among them, keeps
every one. Each passage sits under the section of `AGENTS.md` it belongs to, and an issue or a pull
request named by its number alone, #N, is luainkernel/lunatik's, as there.

## Deciding what to change

What a mechanism past the small shape buys, the shape `AGENTS.md` writes down first, keeps it only
when it is one of two things, with its source: a defect the small shape leaves reachable, traced, or a
need the issue or the maintainer stated, quoted. Fewer reads, more robust, the kernel spells it so:
none of them is either, and the review removes such a mechanism by a fixup. A kernel idiom comes with
the reason the kernel has for it, which the body names. #2083 copied a device's name into a local array
before `lua_pushstring`, which copies it already, for "a read that never walks past the array", which
no trace showed; its review kept the copy for one read per byte, and the maintainer's review took it
out. What `AGENTS.md`, this file or `.agents/rules/` asks of the code, quoted, the helper a grown
function's new step is or the predicate a condition of three tests names, is part of the small shape
and not past it, so no review is asked to make and remove the same helper.

* A decision brought to the maintainer, in a reply as in an issue, a review or a pull request, is one
  he takes in one read: `Decision:` and the question in a line, the options lettered `A)`, `B)`, each
  with what it changes, and `Recommendation:` with the option and its reason; "the maintainer's call"
  names who decides and not what. The options include the smallest change that makes the defect
  unreachable, or, for a need a consumer states, the one that changes nothing in this tree, or, for a
  limit nobody reaches, the clause that documents it, its issue kept open, and each larger one says
  what it buys over it. Each decision carries an ID, `D1`, `D2`,
  kept until it is answered, so the answer is `D3 B`; a text that brings two or more opens with a table
  of them, the ID, the question, the options and the recommendation in a few words each, and gives below
  each ID what its options change. `tools/checks/decision.sh` names a decision without its ID, and two
  without the table.
* A recommendation's reason is what the option buys. That an option leaves an API as it stands is
  not one: the break is a cost of the option that makes it, weighed with the API's users counted, in
  the tree and in the known consumers, against what that option buys. A reason that holds for every
  option, "nothing uses it yet", decides between none. #1965 recommended reading a map's struct value
  by position because the kernel's array was "the existing contract", where a read by name holds when
  a field moves and one test was all the array had; `tools/checks/decision.sh` names a recommendation
  that rests on keeping an API. The reason is what the option buys over the one it beats, named by
  its letter, `B, because over A it ...`: a list of what the option does leaves the maintainer to ask
  what it buys over the others. D19 on #2202 recommended one function under two names,
  `xdp.runtime` and `tc.runtime`, for keeping the names #878's Update had settled, and the
  maintainer asked what that bought over one `bpf.runtime`: a line of `require`; `decision.sh` names a
  recommendation that names no other option.

## Patches and commits

* A subject line is `<area>: <what changes for whoever uses it>`, one plain clause of about 60
  characters at most, with no subordinate clause, "where", "so", "whose", "as ...": the why goes in the
  body. #2484 reached the maintainer as `skb: data() views a copy of a tc callback's non-linear skb,
  where it raised`, he took `skb: data() reads a non-linear skb in a tc callback` in its place, and of
  the titles before it he said "os titulos tao ruins e incompreensiveis". `tools/checks/title.sh` holds
  a subject or a title to the length and the clauses. A body only when there is something the diff
  does not say: a new API, a behaviour change, a non obvious rationale. No bullet list of every detail.
* A pull request carries the `complexity:` label `tools/complexity.sh` prints for it, `small`,
  `medium` or `large` by the lines it adds: the maintainer picks what he reviews by that label, the
  small first, and asked on 2026-11-05 that every pull request take it. An implement-issue run returns
  it among its writes, one opened otherwise takes it as it opens, and one a push moves past its tier,
  a review's fixups among them, takes the new one in place of the old.
* A pull request is one mechanism, read in one screen of diff and one paragraph of body. A body that
  needs a section per mechanism describes several pull requests: stack them, each on the one below.
  A defect master carries that the change fixes on the way, because it reaches the code the defect
  sits in, is one of those, opened on master rather than stacked: the change's branch carries its
  commit first, so either merge lands the fix and neither waits on the other's review.
  The harness is the exception: the checks, rules and skill steps one incident produces travel in one
  pull request, because they carry one reason and the CI line that runs them is one push. They travel with
  each other, never inside an implementation: a rule that rides in a feature's commit lands unread,
  and a maintainer who wants the fix and not the rule has nothing to pick.
  `tools/checks/harness-mixed.sh` names a commit that mixes them.
* A harness pull request the session opened, one whose every file `harness-mixed.sh` reads as the
  harness, merges without waiting for the maintainer once `review.js` ran over its head at `high`
  and returned it ready and its CI passed: what a correction teaches binds the next session that
  day, and the maintainer reads it on master, in the report the merged skill hands him. One that
  `tools/complexity.sh` calls small merges on its CI and a proof instead, a comment of the session on
  it that names its head beside the command that shows the defect before, its result after and the
  case still refused, or, for text no command reads, the passage it replaces beside the new one: a
  mechanical change spends no agent on a review, as the maintainer asked on
  2026-11-22, "devemos atualizar o harness tb para contemplar mudancas mecanicas como essa sem
  queimar token".
  `tools/checks/merge-guard.sh` refuses any other merge the session runs; `MERGE_OK=1` merges one he
  ordered merged in his own words.
* A pull request the maintainer approves in his own words, `2214 aprovado`, is the session's to
  take to master: its fixups fold into the commits they correct, the tree the one he read and the
  messages re-read against it, and it merges by rebase, the head named, with `MERGE_OK=1`,
  waiting for no CI and running no suite, and the merged skill runs. A pull request of his own
  account carries no GitHub approval, so his word is the approval: "o que eu aprovar, vc pode mergear
  vc mesmo", and on 2026-11-15 "o que aprovar, pode seguir sem CI e sem suite".
* Copyright years: a new file carries the current year; a modified file extends its range to include
  it; and a file that factors code out of another carries that file's first year, found with
  `git log -S` on the moved lines. `common/class.lua` took the `:new` that `lib/socket/inet.lua` had
  carried since 2023. Every source file opens with `SPDX-FileCopyrightText` and
  `SPDX-License-Identifier`, the holder being who created it, and a file that cannot carry a header,
  Markdown, data or a font, is declared in `REUSE.toml`; `pre-commit` refuses a source file staged without one.
* A C, Lua or shell source and a Makefile end with a blank line; `pre-commit` refuses one staged
  without it.
