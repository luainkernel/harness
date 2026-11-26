---
paths:
  - "**/tools/**"
  - "**/.agents/**"
  - "**/.claude/**"
  - "**/.github/**"
  - "**/AGENTS.md"
---

# Checks

`tools/checks/` holds the mechanical checks the harness shares, and a project keeps its own in its
own `tools/checks/`, which its rules describe: the comment rules of `.agents/rules/comments.md` read
over C, Lua and shell, the history, a release named with what changed in it or above a table, the
counterfactual, the multi-line note inside code, the trailing comment past the width, a comment on a
signature line or above an internal `static inline` or function-like macro and one naming the file or
function that reads a value (`comment-style.sh`), a comment a change adds to one definition of a block
whose others carry none (`comment-siblings.sh`), the branches, argument tables, inline functions,
aliases and repeated blocks the Lua style rules settle (`lua-style.sh`), the shapes of a function that
is more than one job (`function-shape.sh`), a store that terminates an array no reader takes
(`terminator.sh`), a typedef renamed against a sibling the change removed (`rename-orphaned.sh`), a
local, a function or a global lua-language-server reads as a slip (`luals.sh`), a commit that carries
a rule or a check inside a change of its own (`harness-mixed.sh`), the machine a tracked file carries
and a generated artifact forced past `.gitignore` (`machine-leak.sh`), and the trailing blank line
rule, the refusal of a staged conflict marker and of a source file without its copyright and license
header (`pre-commit`). Each takes file paths and skips what does not apply, so any editor, assistant,
or CI can run them. `comment-style.sh`, `comment-siblings.sh`, `lua-style.sh`, `function-shape.sh` and
`luals.sh` read nothing the `generated` key of the project's `.agents/harness.conf` names, and the last
three nothing its `vendored` key names. `comment-style.sh`, `comment-siblings.sh` and
`lua-style.sh` know a file's language by its extension, and a script with none, as `bin/lunatik` is, by
the interpreter its shebang names. The `Checks` workflow runs them over a pull request's diff:
`pre-commit` and `machine-leak.sh` fail the run, the heuristic checks annotate it. Install the commit
gate with:

    ln -s ../../tools/checks/pre-commit .git/hooks/pre-commit

`advisory.sh` runs the heuristic checks over a change, the file checks over the files it adds or
modifies and the commit checks over its commits, the harness's and the project's own its
`.agents/harness.conf` names under `advisory` and `commit`: the list the `Checks` workflow annotates a pull request
with, and the one `tools/review-packet.sh` hands a review.

`body-identifiers.sh` reads commits rather than files, commits or a rev-range, and names the
identifiers a body carries that appear neither in the commit's diff nor in the code at that commit: what a folded fixup removed, the body
written before the squash still explains. A kernel symbol a body cites
for what the code does not do is named too, so the report is read, not obeyed.

`terminator.sh` reads a C file for a store that terminates an array, `x[n] = '\0'`, and names it when
no call in the file that reads a C string takes that array: a byte written for one reader stays
written after the reader goes. It annotates, since the reader
can sit in another file behind a pointer the array is handed to.

`function-shape.sh` reads a C or a Lua file for the shapes of a function that is more than one job, in the functions the diff against `CHECK_BASE` touches: a lock taken at
more than one site of one function, where the section between is a helper of its own; an allocation
and a raise in one function, where a buffer a raise passes is freed on every raise path and a
userdata the collector frees is the shape; a function past thirty lines or nested past two blocks,
which is more than one job; a per-item buffer sized by a maximum, `n * LUARCU_MAXKEY`, which is packed by each item's length;
a function that existed before the change and grows by five lines or more of it, whose new step is
a helper of its own; and one condition tested at two sites of one function, the bracket of a guard,
which is a pair of helpers that mirror. A Lua function is held to the same length and depth and
to four branches, and named where the change adds it or grows it, in lines or in branches, past them: #2202
grew `call.CALL` by a fifth arm in 24 lines and #948 grew `declare` to 38 lines and ten branches, and
the maintainer asked that both be modularized and that the harness stop the flaw coming back. Its
`if`, `elseif`, `for`, `while` and `repeat` count as branches, and a function the change edits without
growing it is not named. The check annotates: a lock
retaken after a wait is a shape the reader decides on, and the review answers each line it prints with
the function's jobs listed and the fixup that splits them or the reason they are one.

`comment-siblings.sh` reads the lines a change adds, against `CHECK_BASE`, for a comment on one
definition of a block whose other definitions carry none: a run of `#define` lines, the members of a
struct or a union, or a run of Lua `local NAME <const>` lines. Either each has a reason worth a line
or none does, and the reason they share goes in the commit body. It runs at edit time
and over a pull request's diff and annotates, since a definition can hold the one constraint its
siblings do not.

`lua-style.sh` reads a Lua file for the shape rules of `.agents/rules/lua.md` a line-based read can find: an `if`/`elseif` whose branches repeat the same steps, which is a dispatch table
or a helper; one table of arguments spelled at two call sites, which is declared once, named where
the change adds or edits one of them, since a pair the change leaves is not its to fix; and a
function of more than one statement written inline as a table field, which is a named local
function. It runs at edit
time and over a pull request's diff and annotates rather than fails, since two registrations that
share three fields can be two different hooks. It also names a block of four lines or more that a
change adds, read against `CHECK_BASE`, and a script beside it already carries, which is a module they share.
It names a module a file requires twice, which one local holds, as `.agents/rules/lua.md` asks of `linux.genl`,
and an append spelled `t[#t + 1] = v`, which is `table.insert`. It reads the file's own requires: one inside
a long string or comment is text, or a chunk the file hands elsewhere, as `bin/lunatik` hands two to `dostring`.
It names a local at the top of a file of the Lua that runs once on the host, as the `host` key of the
project's `.agents/harness.conf` names it, that a change adds against `CHECK_BASE` and that
takes nothing but functions or tables of a module the file requires into a local, or of the standard
library, `local format = string.format`, `local alu, jump = insn.alu, insn.jump`: a cache of what the
module names, which every compiler pull request of the 2026-11-11 round carried and the maintainer
asked of, "why caching?", of the compiler, which runs once on the host; the Lua the kernel runs keeps
its localized stdlib. A constant the module exports, a field in capitals, a module taken as
`require("linux.xdp").action` and a value computed from a field are not aliases and pass.

`luals.sh` reads the Lua files given with lua-language-server and the tree's `.luarc.json`, and names a
local or a function declared and never read and a global assigned where a local was meant; a `require` nobody reads loads its module into the kernel and keeps
it there for the runtime's life. The configuration turns off what the server infers about types the
bindings' C never declares to it, and says why beside each. It runs at edit time and over a pull
request's diff, and says so where the server is absent.

`author-email.sh` reads a rev-range and names a commit whose author email is not the one the base
uses most for that author's name: a rebase or a squash done from another checkout signs the result
with that checkout's identity. A review and a pull request's preparation run it over
`origin/master..HEAD` before anything is pushed.

A rule is what remains when nothing else can catch the mistake. Where the error is mechanical, the gate
is the answer and the rule is that gate's documentation: a pull request that only writes down what went
wrong, over rules that were already written and already broken, adds a paragraph and changes nothing.
What an investigation teaches lands here, in a skill or in a check, in the same breath as the work that
taught it; a lesson kept in one assistant's notes is one the next contributor pays for again. A rule or
a check that lands is run that day over the open pull requests it reaches, and each one it names gets
a fixup or a reason.

`pr-body.sh` takes a pull request body file and the files its change carries, and fails it on more
than four paragraphs outside its fenced examples, an em dash,
a "Test plan" section or an assistant's footer; `pr-body-guard.sh`, wired before a shell call,
blocks a `gh` write to pulls that carries a body file the check fails on, or that `machine-leak.sh`
finds the machine in; a body it cannot read is refused rather than skipped, as in the review guard below.
A write to a pull request's reviews or comments is that guard's and not this one's, since a review body
runs past four paragraphs by design. A write to issues takes this guard too, since the implement-issue workflow
opens and edits issues from what its agents leave and its prompt asking for the checks enforced none;
`untraced.sh` stands in there for `pr-body.sh`, whose paragraphs and Closes line are a pull request's.
A release takes it as well, through `release-body.sh`, which keeps the em dash, `untraced.sh` and
`decision.sh`, adds the maintainer's rule for public notes, nothing promised of the API or of a release
to come, and drops the paragraph count, since notes run as long as the release.
An edit is read for the lines it adds to the body GitHub has, asked with the credential the command
carries, so text a reporter posted is no edit's to rewrite. When GitHub does not answer, the whole body is read. This guard and the review
guard read a write in every spelling gh takes of it: `new` beside `create`, `-R` before the verb, `-F`
and `-b` on `gh pr` and `gh issue`, `--notes-file` and `-n` on `gh release`, a field attached to its
flag, and the JSON `gh api --input` sends,
whose other fields go through `machine-leak.sh` too; `gh issue comment` is the review guard's. A
write whose text no guard reads is refused: one through curl to GitHub's API, and a GraphQL mutation
other than the textless ones the skills run. So is a write the guards read that its command runs under
`GH_REPO`, set before it, among `env`'s words or by an `export` before it: gh takes the repository from
it and the guards from `-R` and the endpoint, so they read a write to another repository as one to the
checkout's; `-R`, which gh obeys over `GH_REPO`, names it where they read it. GitHub is written through gh, and where gh is absent the
implement-issue workflow reads through curl and writes nothing. An issue a write opens is read by
the project's `contract.sh` too, where it has one, which refuses a finding whose stimulus is out of
the project's contract, and `CONTRACT_OK=1` opens it where a script using the API as documented
reaches the same path. A new issue carries its severity as the repository's label, which
the guard refuses to open it without. A pull request a write opens is read by the project's
`examples-named.sh`, where it has one, over the change from its base to its head, for the examples it
names, and `EXAMPLES_OK=1` opens one whose body says of each what it did. The examples and the contract
are the project's tree's, so they bind a write to the repository the checkout's `origin` names or a fork
of it; the title, the reader and the severity label are the process's, and bind a write to any repository
of the family, that one, the harness's, by the name its checkout's `origin` gives, and those the `repos`
key of the project's `.agents/harness.conf` names (`gh_family` in `commands.sh`); a write to another repository
answers to that repository's own guards. The name of a private repository `LUNATIK_CONSUMERS` lists is held
in every text but one published to that repository, the `origin` of its clone, since an issue filed there
names it by right.

With the change's files, `pr-body.sh` reads three shapes of a body the checks of form passed in #2527's,
which the maintainer received with "vc me fez perder tempo; custa muito para mim iniciar o review humano
em PRs com descricao ilegivel": a first sentence of more words outside its code spans than any a merged
body opened on, #2232's 81, where #2527's ran 86 over a driver its change never reaches; a change
under what the `api` key of the project's `.agents/harness.conf` names, what a script writes or calls, with no fenced block
and no sentence on why no script is shown, "Nothing a script calls changes"; and the commits' words,
a cell, a stimulus, a plan line, a fixup, a squash, "this push", outside a change of the tests or of
the harness, whose subject they are. Without files it asks for no example and looks for those words in
every body. None of the 128 bodies merged from 2026-11-01 to 2026-11-14 fails over its files, and
#2527's first body fails all three. A plain sentence is more than its length, and what the words
mean no check of form reads: `pr-body-guard.sh` refuses the session's post of a pull request body no
reader with none of the change's history passed, the `lunatik-reader` agent, which `review.js` runs
over the body it returns and, with neither phase, over one the session posts (the pr-prep skill).
`body-read.sh` reads the pass from the reader's own run, in the transcript Claude Code keeps beside the
session's, the hook input's `transcript_path`: the text its Write tool left last and the verdict its
answer carries. No agent records a pass: the auto mode classifier refused the reader of #2541's body
the command that recorded one, as "Undermining Oversight", and the guard then refused the body that
reader had passed. A subagent's post waits for the same pass: its hook input carries the session's
`transcript_path` beside its own `agent_id`, so the guard reads the same runs, and implement-issue's
opening posts the file its last reader left, the sentences its build adds read with the rest (#2543).
`BODY_OK=1` posts a body whose text the maintainer read and approved in his own words: on 2026-11-19 the
reader failed five texts in a row of the pull request split out of #2630, each time on points the last
one had not raised, and the maintainer approved the sixth.

`title.sh` holds a pull request title or a commit subject to the shape AGENTS.md, *Patches and
commits*, gives a subject, `<area>: <what changes for whoever uses it>` in one plain clause, which the
maintainer asked for after #2541: "precisamos alem dessa melhoria no corpo, melhoria no titulo tb.. os
titulos tao ruins e incompreensiveis.. o corpo melhorou". It names a title with no area before its
colon, one past 60 characters and one that carries a word opening a subordinate clause, his "where",
"so", "whose" and "as ...", and their kin, which, since, because, unless, when, while, whereas, though,
although and if, its code spans left out, and a name that holds one, `socket.so`, is none; a relative
"that", as in #2223's `luaebpf: refuse a verdict that is not an action of its type`, is part of a plain
clause. A `fixup!`, `amend!` or `squash!` subject, a revert, the `Reapply` of one and a merge pass as
git writes them. The seven titles he took on 2026-11-15 for #2202, #2222, #2223, #2235, #2484, #2485
and #2545 pass, and the seven they replaced fail, two on the length alone; of the 265 titles merged
from 2026-10-17 to 2026-11-14 it names 233, 231 of them past the length, and of the 355 subjects master
took in that time, 322. `pr-body-guard.sh` refuses a write that gives a pull request of the family
a title it names: `--title` or `-t` of `gh pr create`, `new` or `edit`, gh api's `title` field, read
from the file `-F title=@` names, and the JSON `--input` sends. It refuses too a title it cannot read,
one the shell expands or a file the same command writes holds, and a `gh pr create` given none, which
opens under a commit's subject or the name of the branch. `commit-msg` refuses a commit whose subject
it names, reading the `title.sh` beside the hook, so a worktree on a base older than the check commits
under it too; it is installed as `pre-commit` is:

    ln -s ../../tools/checks/commit-msg .git/hooks/commit-msg

git runs it on a commit, an amend and a merge, and not on the picks of a rebase or a cherry-pick, so a
branch written before the rule restacks. `advisory.sh` runs the check over a change's subjects, which the
`Checks` workflow annotates and a review's packet carries; the implement-issue workflow's implementer
runs it over its title and its subjects, `review.js`'s reviewer over the title it is handed, which it
returns corrected, and the `lunatik-reader` agent restates the title from the title alone before it
reads the body.

`rewrite-guard.sh`, wired before a shell call, refuses a forced push of a branch other branches are
based on, naming them: they keep the commits the push drops, and those surface later as a duplicate
of a commit that no longer exists, in a pull request nobody edited. It reads the push through
`commands.sh`, since the raw text read an `rm -f` beside a quoted push as one, and reads those branches
against the head the push replaces, the one its lease names, else the remote-tracking ref, else the
local branch: a restack moves the local branch to the new head before the push, and the branches based
on that are the ones already rebased. `REWRITE_OK=1` runs it once that list is known to be stale.

`stacked-guard.sh`, wired before a shell call, refuses opening a pull request on a base other than
the trunk, unless it opens as a draft: the branch `origin`'s HEAD names, else `master` or `main` as
`origin` carries it, in the checkout's repository, and the default branch GitHub answers for another the
write names, as a bump opened from the mount names the project's. GitHub does not merge a draft, and
nothing else stops a stacked pull request merged before its base from going into the base's branch. A pull request moved onto such a
base is made a draft first, `gh pr ready --undo <n>`, which the guard asks GitHub.

`merge-guard.sh`, wired before a shell call, refuses a merge the session runs unless GitHub answers
that it is a harness pull request an agent's review passed: opened by the posting account on the
repository's default branch, as GitHub names it,
every file the harness as `harness-mixed.sh --outside` reads it, the mount a bump moves among them, or
any file of the harness's own repository, and a head that carries the
`agent-review` status, which the merged skill sets once `review.js` returned that head ready, or, on a
pull request `complexity.sh` calls small, a comment of the posting account that names that head, the
proof a mechanical change merges on (AGENTS.md, *Patches and commits*), and
passed every check run, and commits none of which is a `fixup!`, `amend!` or `squash!`, which the
`Checks` run warns of without failing. A bump of the mount, a pull request whose one file is the
submodule, carries no status of its own: the commit it pins does, on the harness's trunk, where the
merged skill sets it after the merge, with the check runs the push to that trunk started, all passed.
It refuses a merge other than by rebase too, the way the maintainer's merges land and the merged skill
reads them. A commit status is GitHub's answer to a merge gated on a reviewed
head, the check branch protection requires; the guard reads it itself, since branch protection is the
maintainer's setting and would gate his own merges. `MERGE_OK=1` merges one he ordered merged in his
own words.

`fixup-guard.sh`, wired before a shell call, refuses opening a pull request whose head, compared on GitHub
with its base, carries a `fixup!`, `amend!` or `squash!` commit: a pull request reaches the maintainer's first
review squashed, and a fixup is how he reads what changed after it. `FIXUPS_OK=1` opens one that is not the
first he reads. It and `stacked-guard.sh` read the refs a write names in every spelling
`pr-body-guard.sh` reads, the JSON `gh api --input` sends included; beside `--input`, gh sends the fields in
the query string, so the draft stacked-guard counts there is the JSON's.

`fixups.sh` names the `fixup!`, `amend!` and `squash!` commits of a rev-range, and the `Checks` workflow
warns of one on a pull request without failing the run: each round of the maintainer's review pushes a
fixup, and a red run per round filled his mail, 69 of the 96 failed runs from 2026-11-14 to 21.

`discard-guard.sh`, wired before a shell call, refuses a command that writes over a file holding a
change nobody committed, a checkout or a restore of a path, `git reset --hard`, and a checkout or a
switch that forces, naming the files: a session that meant to put back its head's version of two
guards typed `origin/master`, and the edit it had made over them went with no copy left. A defect
planted to prove a test is a patch reverted with `git apply -R`; `DISCARD_OK=1` writes over files
known to hold nothing to keep.

`unanswered.sh <pr>` reads a pull request on GitHub and names each comment a person left there that no
reply of the session answers: an inline one whose thread holds no later reply of the session's, and one
of the conversation, or a review's body, that no later comment of the session quotes by its first line
outside a quote. The session posts from the maintainer's account, so its posts are told from his by the
note each opens with. #2630's review asked whether the collector could be stopped in an `scx` callback,
and the answer reached the session's chat alone.

`stage-guard.sh`, wired before a shell call, refuses staging the whole tree, `git add -A`, `--all`, `-u`,
`--update`, `.` or `:/`, and `git commit -a`: a commit is staged by purpose, and a tree an edit left with
several changes in it otherwise fuses them under a message that explains one. `STAGE_OK=1` stages a tree
that holds one change only.

`scratch-guard.sh`, wired before a shell call, refuses a recursive `rm` of `scratch` itself, of a path one
component under it, or of everything such a path holds: that is a workflow's scratch directory, where every
phase of a batch keeps its checkpoints, defect patches and worktrees, and a phase removes its own worktree,
two components down, never the directory beside it. The build of #2080's run removed `scratch/b2066` whole
under the runs in flight, and the next build found its defect patches gone (#2123). `SCRATCH_OK=1`
removes one known to hold nothing of another run's.

`cd-guard.sh`, wired before a shell call, refuses one whose working directory, the `cwd` the hook input
carries, which follows the session's `cd`, lies under the checkout other than its root, until a call
opens with `cd` back to the root: Claude Code keeps the directory a `cd` leaves for every later call,
and its own check refuses to remove the session's working directory, so the `rm -rf` that ends a scratch
worktree the session had entered fell to the maintainer as a script, three times on 2026-11-16 and 17. A
subagent, whose `cd` lasts one call, and a worktree Claude Code enters under `.claude/worktrees` pass.

`message-guard.sh`, wired before a shell call, refuses a `git commit` whose editor copies a message in,
`GIT_EDITOR="cp <file>"`, or edits the file `-F` reads, when that file holds a line that opens with `#`:
git cleans a message an editor gave in strip mode, which drops such a line without a word, and an amend!
for #1917's design note lost "#1905 settles..." that way. `-F` alone keeps it, and so does
`--cleanup=whitespace`; `MESSAGE_OK=1` commits the message as git cleans it.

`implement-guard.sh`, wired before a shell call, refuses a commit in the session's own thread that
carries code, a path the `code` key of the tree's `.agents/harness.conf` matches, staged before the
call or by a `git add` in it: an implementation is written by
implement-issue's agents, whose calls carry the `agent_id` a main thread's never does, so its
implementer and its review are not the session's. A fixup, a squash and an amend pass, since they
correct a commit a review reads, and `IMPLEMENT_OK=1` commits one the maintainer asked the session to
write itself.

`luals-guard.sh`, wired before a shell call, refuses a push whose tree adds, on a line its branch
introduced against the merge base with `origin`'s trunk, what `luals.sh` reads as a slip; what the branch
inherited is not the push's to fix. `LUALS_OK=1` pushes a name that is the code's on purpose.

`memory-guard.sh`, wired before a shell call and before Write and Edit, refuses a call that leaves in
Claude Code's memory, a file under `.claude/projects/<project>/memory/`, a memory of type `feedback`
when what the call adds names no path of the repository where its lesson lives, `AGENTS.md` or a path
under `.agents/`, `tools/` or `doc/`. A session wrote a lesson there and not into the tree, and the
maintainer asked "pq para a memoria e nao para o repo?", then for a guard "para nao repetir esse erro de
deixar em memoria local apenas": the lesson goes into the tree first, through a pull request, and each
write to the memory names where. A `#N` is no such path: the append that prompted the guard named #2541,
to a memory that named `AGENTS.md` already, and the lesson it carried was in no file of the tree. A
lesson that belongs to no place of the public tree, the language of the conversation, the tone, a
private consumer, is a memory of type `user`, and naming `CLAUDE.local.md` does not pass it as a
`feedback` one. The other types pass. The index, `MEMORY.md`, carries none, and a call that adds to it a
link the index does not hold yet is refused when the directory holds no such file, or holds a lesson
whose own text names no path of the tree: a session wrote a lesson the guard refused and, in the same
turn, a `sed -i` that added its line to the index, which then pointed at a memory that did not exist,
and the maintainer asked "pq colocou no MEMORY.md? deveria ter guards contra isso". A link to a `user`,
`project` or `reference` memory passes, and so does one the index holds already, so a line reworded
keeps its link; the index lists a memory once the call that writes it has landed, so a call that writes
both is refused, and the memory goes first, in a call of its own. What a call adds is what Write
writes, the `new_string` of an Edit and the whole command of a shell write, a
redirection, a `tee` or a `sed -i` into a memory read through `commands.sh`, its path spelled whole,
through a variable the command assigns or under a directory it changes to, as
`cd <memory> && cat >> <file>` spells it, a relative path read under every directory the command
changes to: a path the command names anywhere passes it, and a write a script makes, `python3` over a
heredoc, is not read. The type is read in the memory as the call leaves it, for a shell write the file
as it stands with the command beside it, so an Edit that makes a memory a `feedback` one is held too,
and one that makes it a `user` one passes where a `sed -i` of the same line is refused.
Every later write to such a memory, a typo fixed included, names a path in its own text, and a Write of
a whole memory that names one passes whatever else it adds. Its cases give Write and Edit their whole
input as JSON, beside a fixture that holds the memories an edit and an append read.

`question.sh` reads a message the maintainer sends for a question, a question mark or an opening
interrogative, and `.claude/hooks/on-prompt.sh`, run as the message arrives (`UserPromptSubmit`), tells
the turn that it answers and changes nothing, and reads no background task's notification, which reaches
the turn as a prompt the maintainer did not write: "what is left?" drew seven implement-issue workflows that
had to be stopped, when it asked for the list. An order closed by a confirmation tag, "...; entendido?", is a
question too, and the check reads it as one: #1865 asked it to read such a message as an order, and the
maintainer closed it, since the tag asks whether the order was understood.

`table.sh` reads the same message for a request for a table, "tabela" or "table", and `on-prompt.sh`
tells the turn how much a cell holds: Claude Code wraps each cell to the width its column gets and, when
one runs past four lines or the table past the terminal, prints every row as `Header: value` lines. A
reply that answered "numa tabela" with a paragraph in each cell reached the maintainer as no table at
all, in four sessions.

`context.sh` reads a session's transcript, the hook input's `transcript_path`, for the context its last
request carried, what it read from the cache, wrote to it and sent uncached, and `on-prompt.sh` tells a
turn past 300k tokens to write a hand-off at the next boundary, a run returned or a pull request merged,
to the project's `scratch/handoff/` under the session's id: the open decisions by their IDs, the runs in
flight with their scratch directories and the pull requests that wait, and then to say the session can
be cleared. Each request carries the whole thread again: from 2026-10-28 to 2026-11-25 the sessions' own
thread weighed 33.8% of all the project's requests, 77% of its requests past 300k tokens, and the
maintainer chose the hand-off over a compaction at the boundary, whose summary is all that survives of
what the session corrected (luainkernel/harness#6, D175). A compaction's boundary stands for the
request it replaced, with the context the compaction left, so the prompt after one is not read at the
size before it. `.claude/hooks/on-start.sh`, run as a session starts or is cleared (`SessionStart`,
matchers `startup` and `clear`), lists the hand-offs there, newest first, to the session that starts.

A check ships proved, the way a test does: run it against the mistake it is for, and against a case
it must pass. A condition that cannot fire reads as protection and is none, and nothing downstream
catches it. A command guard whose verdict the command alone decides keeps those cases in
`tools/checks/cases/<guard>.cases`, which `cases.sh` runs and the Checks workflow runs on every pull
request, so a change to the guard or to `commands.sh` beneath it is read against them again: the
`git -c` whose value held a space passed push-guard.sh for as long as nothing ran its cases a second time.
A command guard whose verdict also reads the repository the command runs in keeps its cases there
too, beside `<guard>.fixture.sh`, which builds that repository in a scratch directory the cases run
in: `rewrite-guard.sh` refused a restack's push naming the branches already rebased onto it, and
another naming a detached HEAD as four branches, with no case to read either against. One whose
verdict reads the process table keeps them too, and its fixture starts the process it reads, which ends
with the directory: `lunatik-lock.sh` had none, its verdict waiting on a busy device, and passed the
marker a call's description carried. While they run, every session on the machine reads the device as
busy.

`lunatik-lock.sh`, wired before a shell call, refuses a command that touches the device, an install, a
reload, a run, a `list`, `-V`, the REPL on a pipe or with `-e`, or a suite, while another operation is on
it, naming the processes it found; a process in
D state among them is the wedged device, which no waiting clears. `LUNATIK_LOCK_OK=1` overrides it once
what it lists is known to be stale. Its refusal names the wait for a cycle that holds
`tools/lunatik-host`, `bash tools/lunatik-host true`, which returns once that cycle ends: the shell a
tool runs a command in carries its text, so a wait over `ps | grep` or `pgrep -f` finds itself, and three
builds of 2026-11-13 waited an hour in such loops.
What a command runs is read by `commands.sh`, which the command
guards share: a CLI verb, `make install`, a test script or `watchdog.sh` counts when it is the command,
read through `sudo` and `env` with their options, `tools/lunatik-host` and a shell's `-c` string, and
not when it is handed to `git`, `grep` or a check, to a shell's `-n`, which reads it and runs nothing,
or written into a file by a heredoc. The post guards read through it too, the `gh` command that writes and not the raw input; an approval marker counts only in the command, in every guard, since the raw input carries the description too. A cycle a script file runs names nothing a
text can read, so it goes through `tools/lunatik-host`, whose lock orders it against the cycles that
take it too.

`functional.sh` takes a base and a head, reads the base from where the head forked from it, so a base that
moved past the fork point does not lend the change its later commits, and names the files of the change
that the host cycle reads: a C
file whose tokens differ once the comments are gone, a Lua file whose stripped bytecode's listing does, read
without the lines its functions span, a shell script with a line other than a comment changed, a submodule
whose commit moved, and any other file whose bytes or mode moved, past the documents, the harness, its
mount and the scripts under `tools/` but what the `tools` key of the project's `.agents/harness.conf`
names, the `.gitignore` files and what its `unread` key names, which nothing the host runs reads. When it
names none the change is not run, and the review's build phase skips a head that moved only that way past
the validated head, or past the base on a first build, which has none: a comment shortened on #1903 went
through install, reload and two suites, which measured the module they had measured before, and a sentence
of a guide page on #2231 through a whole suite, its first build having no validated head to read past.

`tools/watchdog.sh` runs a script and stops it when the host loses the connectivity it had before the
run, comparing against the loopback and the default route's gateway and holding nothing against the
script that was already unreachable; a stop that does not return is a wedged device, which it reports
and only a reboot clears.

`machine-leak.sh` reads a tracked file for what belongs to the machine it was written on: an absolute
path in a home directory, a password handed to sudo, a credential read out of a file or carried inside a
URL, a literal shaped like a token, a staged path `.gitignore` keeps out, which only `git add -f` puts
back, and the name of a private repository, which it takes from
`LUNATIK_CONSUMERS`, a colon separated list of the machine's clones of private repositories, and
never spells itself, so that rule is silent where the variable is unset. It is a
gate and not a nudge, so it fails the commit and the run rather than annotating them: what is committed
is read by everyone who clones, and a credential committed once is a credential rotated. It reports the
file, the line and the rule, never the text it matched, which would otherwise reach a terminal and a CI
log. What belongs to one machine lives in that machine's environment or in its untracked
`CLAUDE.local.md`, and reaches the tree as an argument whose default names no host. `leak-guard.sh`,
wired before a shell call, reads with it what a push publishes besides the files, the messages of the
commits past `origin`'s trunk and the names its refspec carries, word by word, and refuses the push
that leaks; a branch pushed with a private clone's name in its messages and in its own name was read by
nothing until it was public.

`tools/pr-status.sh` prints the open pull requests as GitHub has them: base and whether it still merges,
commits and how many are unsquashed fixups, the size, the CI conclusion, and the labels; `--ready` keeps
the ones a maintainer can pick up. What GitHub cannot see is whether anyone read one, so the review
workflow labels what it finished with `workflow-reviewed`, and a pull request without that label has
had no second reader. Which pull requests are open, reviewed or ready is read from it, not from memory.

`tools/issues.sh <epic>` prints the issues an epic tracks as GitHub has them: the epic and each issue
whose body says it is part of it or that the epic's task list names, its state, and the pull
requests whose body names it with what each does to it, flagging an open issue a merged pull
request names and a merged pull request that closes none. An issue closes, and its card on the
project board moves to Done, only when a merged pull request
says `Closes #N` or someone closes it by hand. A pull request that finishes a phase carries `Closes #<phase
issue>`, one that finishes none says `#<epic>, which it does not close`, and `pr-body.sh` fails a body
that says Part of, Top of, Bottom of, Answers or reported as and does neither. After the maintainer
reports a merge, the session runs `tools/issues.sh` over the epic, closes what the merge finished and
GitHub left open, an issue the pull request only named or an epic whose issues are all closed, and
hands him in the same message what closed and what stays open; the board moves a card with its issue.
What a release still lacks is read from the same report, the epic's task list included.

`review-post-guard.sh` reads the tool command on stdin instead of a file, for an assistant wired
to run it before a shell call (`PreToolUse`): it blocks a `gh` write to reviews or comments on a
pull request or an issue the posting account did not open unless the command carries the `REVIEW_POST_OK`
marker, set once the exact text has been shown to the maintainer and approved, or when the text
gives a fixup reference as a backtick'd SHA, which renders as code and does not link. The marker
forces the show-then-post step; it cannot check that the text was shown, only that it was set on
purpose. A pull request or an issue the posting account opened is the maintainer's own, the issues
the implement-issue workflow files under his account among them, and a post on it needs no marker:
the guard asks GitHub who opened it, with the credential the command carries, and asks for the
marker whenever it cannot tell. On 2026-10-20 two comments the maintainer approved, closing issues a
workflow had filed, were held for the marker as if those issues were a stranger's, and the auto mode
classifier read the marker as a guard bypassed and refused them. The text goes through `machine-leak.sh` before
the marker is read, since the marker approves the wording and not what the wording carries, and text
the guard cannot read, passed inline or on stdin, is refused rather than skipped. Every text it lets
through opens with GitHub's note that an LLM wrote it, `> [!NOTE]` and, on the next line,
`> This review was written by an LLM, not a human.`, `This comment` in an inline comment or a reply,
the review body and each inline comment alike, since the account is the maintainer's and an inline
comment stands alone in the conversation. A case of it that carries the marker asks GitHub nothing, and one that does not asks a gh its fixture writes. A post it holds for
the marker is recorded for the session, and `pr-body-guard.sh` refuses an edit that adds text other
than a task to the body of the same issue or pull request until the marker is set, so the approval is not skipped by another route. A
comment given to gh's `close` or `reopen` is refused as text no file carries, since that route has no
file to read.

`untraced.sh` reads a text about to be published, a review, a comment, a pull request body, for the
word that names a failure nobody read: a failure that comes and goes is read in the journal around the
failing run, `tools/journal.sh` prints every unit's lines in that window, and the text names the
mechanism or carries a hypothesis with what was not captured. `pr-body.sh`, `review-post-guard.sh`
and, on an issue body, `pr-body-guard.sh` run it.

`decision.sh` reads the same texts, where the same three run it, for a decision handed to the
maintainer without the question, two options and a recommendation (AGENTS.md, *Deciding what to change*): it
keys on the phrase that hands one over, "the maintainer's call", "é decisão sua", "levo isso a
você", and asks the text around it for the three. A reply in the session is where the maintainer
read "é decisão sua", so `.claude/hooks/on-stop.sh`, the Stop hook, runs it over the reply a turn
ends on and sends one that fails back once, passing the stop after it (`stop_hook_active`). A decision reported as taken, "foi decisão sua", "por decisão sua", or said to be none, "não pede decisão sua", "nenhuma decisão sua", hands nothing over and passes.
It also reads every recommendation, from the line that opens with one, `Recommendation:`, `Recomendação:`
or `Recomendo`, to the end of its paragraph, for a reason that rests on keeping an API, "the existing contract", "não
muda a API": that is a cost the other options pay, not what the recommended one buys (AGENTS.md,
*Deciding what to change*), and #1965's recommendation of a positional read rested on it. One that
spells the break as the cost of the option that makes it, "B breaks `bpf.map`'s API, which one test
uses", passes. It also names a recommendation that names no option it beats, by its letter in a
comparison, "over A", "sobre A": the reason is what the option buys over that one, and #2202's D19
recommended one function under two names, the maintainer then asking what it bought over one name.
A decision, two lettered options and a recommendation, that carries no ID `D1` is named,
and so are two or more brought without a table whose rows open with their IDs: the maintainer answers
by the ID, `D3 B`, and asked for both after a reply that made him spell out which decision he meant.

`reboot-capture.sh` reads the same reply in the same hook, for a request for a reboot the checkout
holds no capture for: the host is the one both projects run their suites on. `tools/prereboot.sh` saves what a reboot erases for every session on the host,
and the others learn of the reboot when it is done, so the session that asks runs it. It
keys on the phrase that asks, "preciso que você reinicie", "can you reboot"; one that says what only a
reboot clears, "só um reboot resolve", "needs a reboot", counts only while the host is stuck, a module
`pinned.sh` names or a `lunatik` process in D state, since on a sound host it describes what a bug
would leave. It passes when `scratch/reboot-*` holds a capture taken in the last hour.

`handoff.sh` reads the same reply in the same hook, for a command handed to the maintainer to copy: a
line opening with `! `, Claude Code's prefix for a command he runs in the session, longer than 60
characters or continued on the next. A step only he can take reaches him as a script under `/tmp` and
the one line that runs it (AGENTS.md, *Deciding what to change*); on 2026-10-11 a reply handed him the
delete of the 21 branches a merge left as one line of 600 characters. A command handed without the
prefix is not read. It also opens the script a `! bash /tmp/<name>.sh` line names, and names one that
writes to GitHub with `gh` and runs nothing under `sudo`: a post is the session's once the maintainer
says to post, since the auto mode classifier reads his go in the conversation.

`citation.sh`, `tldr.sh` and `settled.sh` read the same reply in the same hook. `citation.sh` names a
line that says what AGENTS.md, a rule or a skill asks without the passage in double quotes, or with
one that no Markdown file the harness or the project tracks holds: a reply recommended a split because "the
AGENTS asks" for it, of a rule nobody had written. `tldr.sh` names a reply of more than 15 lines that
does not open with a TL;DR of five lines at most, since the maintainer asked for one after a plan of
20 and a report of 21. `settled.sh` names a decision line that asks whether to file a finding, which
the conventions settle: the finding is filed and the reply says its number. It names one that asks
whether to post the label, the `Update:` or an issue an implement-issue run returned too, which the
maintainer ordered posted always.

`.claude/hooks/on-compact.sh`, run as a session starts again after a compaction (`SessionStart`, matcher
`compact`), prints into its context the rules a compacted session broke, each read from AGENTS.md or
`.agents/rules/` by the words it opens with, so the hook keeps no copy: what the session corrected
before the compaction survives only in the summary. A rule reworded past its opening is named
instead of printed, and the hook's list follows it.

`push-guard.sh`, wired before a shell call, refuses a `git push` in a command that also runs a
rebase, a merge, a cherry-pick, an am or a revert, and one from a tree with any of those in progress:
the one that stops on a conflict leaves HEAD on the base with the branch's commits still to apply,
and a push chained after it publishes that base as the branch. The push is a command of its own, after `git status` has
been read; `PUSH_OK=1` overrides the guard for a push meant while a rebase stays paused in another
tree. It also refuses a lease whose expected value is a full hash the push's tree resolves to no
commit, `git rev-parse --verify` read in that tree: git sends a full hash it does not hold, and the
remote refuses it as stale info, "failed to push some refs", with no word of the lease. On 2026-11-06
and 2026-11-10 a session completed a branch's head from the nine characters it had seen, twice a hash
that does not exist; the value comes from the checkout, `--force-with-lease=<branch>:$(git rev-parse
origin/<branch>)`, which the refusal spells. A lease with no value, or one spelled as a ref or an
abbreviated hash, git resolves before it sends, and refuses there when it cannot, and the guard leaves
it to git; `PUSH_OK=1` does not pass a lease it refuses.

