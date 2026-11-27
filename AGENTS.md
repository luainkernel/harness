# Working on a project that mounts the harness

The rules every project that mounts this repository keeps, Lunatik and luaebpf among them, for
contributors and for AI coding assistants working on one. Each project carries its own AGENTS.md
beside this file, which points here: this file holds what binds them all, `CONVENTIONS.md` the
conventions Lunatik and luaebpf share beyond it, which a project imports or keeps its own in place
of, and the project's file what speaks of that project alone, its layout, its build and its kernel
rules. An issue or a pull request named by its number alone, #N, is luainkernel/lunatik's, where the
history of these conventions up to this repository's first commit stays.

Lunatik runs Lua inside the Linux kernel, and luaebpf compiles Lua to eBPF for it, on a host other
sessions share. A mistake in the kernel does not raise an exception, it panics the machine. One rule
follows from that and outranks everything else in this document:

**Verify, do not assume.** How the kernel behaves is read in its source, not inferred from a
measurement: which CPU a hook runs on is answered by `NF_HOOK`'s callers, and a run on one host
confirms that reading, it does not replace it. Before using a kernel API, read its declaration in
`/usr/src/linux-headers-$(uname -r)/include` and confirm it is exported in `Module.symvers`. A
kernel interface read at runtime rather than linked — a `/sys` or `/proc` path and the format it
returns, the `/dev/lunatik` protocol — is held to the same rule: confirm it against the source
across the supported kernel range (6.6 and later), not from the one kernel you happen to run.
Signatures and formats change between releases. If you have not checked, say so instead of
asserting.

## The harness in a project

A project mounts this repository as a git submodule, and every path this file, the rules, the skills
and the scripts name under `tools/`, `.agents/` and `.claude/` is the harness's, under that mount;
the project keeps its own checks, rules and skills at the same paths of its own tree. What a shared
script reads of the project it reads from the checkout, its `origin`, the branch `origin`'s HEAD
names and where the mount sits, or from the project's `.agents/harness.conf`: the paths its tree
reads as code, as what a script calls, as its own tools and as what the host never reads, the
checks of its own the shared adapters run beside theirs, and the conventions of `CONVENTIONS.md` it
replaces. `tools/checks/project.sh` reads both and
says what each key is for. What the shared workflows do of the project's own, its build, its suite,
its kernel readings and its contract, they do as the project's AGENTS.md asks: a prompt says so in a
clause and restates none of it, as *Skills* says of a prompt, and the host's agent, which loads no
CLAUDE.md, reads that file in its worktree.

## Build, install, test

Never run two `lunatik` operations at once. Concurrent operations wedge `/dev/lunatik` and leave
processes in D state. `ps` answers for the instant it ran, which is no help when another session
starts a second later, so a build-install-run cycle takes the lock instead:

    bash tools/lunatik-host sudo lunatik test
    bash tools/lunatik-host bash tools/watchdog.sh examples/systrack/device

It runs the command with the lock held, names the holder while it waits, and releases on exit
however the command ends. The installed tree under `/lib/modules/lua` is shared too: a suite run
whose totals do not match the tests in your own worktree is a mixed install, one session's modules
against another's scripts, and it measures neither.

A worktree named for a task may belong to another session on the same machine. Check
`git worktree list` and the branch a worktree holds before a checkout or a reset there, and never
reset a branch checked out elsewhere. A review, or a build of a branch not your own, runs in a
worktree created for it (`git worktree add`, then `git submodule update --init`) and removed at the
end, with `rm -rf` and `git worktree prune`, since `git worktree remove` refuses a tree with
submodules. Each one left behind carries a build on the disk every session shares, and a build that
stops halfway on a full disk leaves the previous install in place for the suite to measure:
`tools/checks/disk.sh` fails below a free-space threshold and names the largest worktrees, and
`tools/lunatik-host` runs it as a warning before every cycle. A `git checkout` carries what is
uncommitted onto the new HEAD, where an edit made against the old base reads as a change to the new
one: switch branches in a tree with nothing pending, or read the other branch in a worktree of its
own. `git stash` has no place here at all: the stack belongs to the repository and not to the
worktree, so `stash@{0}` is usually another session's work and the pop that follows spreads its
conflicts over your tree. Set work aside with a commit, and compare two revisions with a worktree or
`git show <ref>:<path>`. What a worktree holds built and not run is code nobody ran: a cycle run in
a worktree not your own installs its author's untested edit, and an edit left built while its author
waits on a question is a crash any session can trigger. An edit is built, installed and run in one
step, or reverted before the session pauses. A session's scratch worktrees live under `scratch/wt/`, since the
reboot such a crash forces clears `/tmp` and every tree it held, and a script a cycle reruns lives
under `scratch/` for the same reason; `tools/lunatik-host` names one it runs from `/tmp`.

A change the host does not read, a comment, spacing, a document, is not run at all: the suite would
measure what it measured already. `tools/checks/functional.sh <base>` names the files of a change that the
build, the install or the suite reads, and when it names none the change goes out on the checks alone.

A tree with a conflict pending (`git status` showing `UU`) is not a test subject: a suite run over a
half-applied rebase or cherry-pick measures neither side. Resolve and commit, then build.

### Checks

`tools/checks/` holds the mechanical checks, the harness's here and a project's own in its tree, and
`.agents/rules/checks.md` says what each shared one reads, the mistake it is for and the guard it backs.

### Skills

`.agents/skills/` packages the recurring workflows — the review of a pull request, its preparation, an
issue implemented through agents, a merge, a release — as agent skills in the open `SKILL.md` format
([agentskills.io](https://agentskills.io)), discovered by any compatible assistant. Each one
defers to this file as the authority and orders the steps; none replaces reading it. A project's own,
its build cycle among them, live in its tree.

For Claude Code, a project's `CLAUDE.md` imports this file, `CONVENTIONS.md` where it keeps the
harness's conventions, and its own AGENTS.md, its
`.claude/settings.json` runs the command guards and the file checks as hooks, the shared ones from
the mount, and its `.claude/skills/` links to the skills of both; nothing there holds logic of its
own. Claude Code's settings include no other file, so this repository's `.claude/settings.json` is the
list of the shared hooks each project's repeats under its mount. Those files, and an untracked
`settings.local.json` beside them, bind every session opened on the checkout rather than the one that
wrote them: a `permissions.deny` added
there to sandbox one session's agents denied another session's commands, with no hook error to
point at the cause. A sandbox belongs in an agent definition, or in a session started with its own
permission mode. The checkout sessions start in is what every session and every agent it launches
loads, this file, the skills and the guards, so it follows master: `checkout-behind.sh`, which
`.claude/settings.json` runs as a session starts, prints how far its HEAD is behind `origin/master`
and the `git merge --ff-only origin/master` that brings it level, with the `git submodule update` of
the mount that a fast-forward leaves behind, and the session runs them when the checkout has no commit
of its own and nothing tracked changed. It fetches nothing, since the
remote-tracking ref is shared by every worktree's fetch.

An agent that works on this tree runs through the Workflow tool, whose `agent()` takes the model and
the reasoning effort, and the maintainer's opt-in to workflows stands here: the Agent tool takes a
model and no effort, so what it launches runs at the default effort whatever was asked. `agent-guard.sh`, wired before the Agent tool, refuses every type but a read-only search
and the Claude Code guide; `workflow-effort-guard.sh`, wired before the Workflow tool, refuses a script
whose `agent()` calls never name an effort. An agent a running workflow waits on is not messaged: the
message resumes a copy of it from its transcript, which runs beside the original in its worktree and on
the host.
`send-guard.sh`, wired before SendMessage, refuses one whose run's journal holds no result for it; what
its report asks for is done outside it, on the host or in an issue, or by stopping the workflow and
relaunching it with notes.

An issue goes to agents through the implement-issue skill's workflow: a groomer, when the launch names
one, first judges whether and how the issue is to be done, an implementer commits the
change, review-pr's workflow runs over the branch nested, so a review runs one way whoever launches it,
and its build is the one run on the host, in an agent of its own, before the pull request opens; so
does a shape a review proposes, and `implement-guard.sh` refuses a commit of code in the session's
own thread that is not a fixup. An
agent's context is paid for on every turn it takes, so the work that only waits on the host, or only
writes to GitHub, runs in agents `.agents/agents/` defines that load no CLAUDE.md and run on a
smaller model, and a pull request body is read in one that loads none so that it knows nothing of the
change. The implementer's prompt names the rule a step needs and restates
none: every agent loads this file, and a rule pasted into a prompt is a copy the next change here
does not reach.
What the implementer and the review leave as issues, their `findings_left`, the workflow prepares as its
last stage, once an agent read each one's premise in the tree, each under its severity label or
appended to the open issue it belongs to, and returns as
`writes` with the pull request's label and the groomer's `Update:`, which the session posts as the run
returns: the auto mode classifier refuses a workflow agent's write to GitHub. An entry quotes the
contract its severity was read against, which the issue carries as a `Contract:` line. The implementer's
answer and the reviewer's each carry the smallest shape beside the size of the diff and what every
mechanism past it buys, and the hand-back shows it.

## Rules by path

The rules for a kind of file live in `.agents/rules/`, each opening with the paths it governs, and Claude
Code loads one when a file it reads or edits matches, through `.claude/rules`, which links there. Another
assistant reads the ones whose paths match the files it touches.

## Deciding what to change

Code on `master` is not settled. When a new design makes an existing mechanism simpler, or subsumes
it, change or remove it. Working around it to keep a diff small leaves two mechanisms doing one job,
and every later change has to serve both. Authorship is not a reason to keep code, and neither is how
recently it was merged; a commit that removes or subsumes something already on `master` names it in
the body.

The first shape of a fix is the smallest change that makes the observed defect unreachable, and
every mechanism past it is named with what it buys that the small one does not. A structural
answer the kernel offers is not the smaller one by being structural: four lines that decline a device
of another namespace in the handler fixed #797, where moving the netdevice block to the per-namespace
chain took a macro signature, two wrappers and an API newer than the tree's floor. Write the
small shape down first, even when the larger one is chosen, so the choice is a comparison and not a
default.

An issue states the need, its contract and the API the maintainer settled, the types, names and calls
a script sees, and leaves the code's inner structure to whoever implements it: a sentence that
prescribes a helper, a loop or a step two functions share is read as the spec, and weighed by no one.
#1895 asked the two walks of a set to share the step from one level to the next, and #1896 wrote
`luaset_next` and kept it because the issue asked, where the tree spells a loop that two functions
share as a foreach macro.

Each deliverable that an epic, a phase of one or a design note plans names the maintainer's words or
the issue that asks for it, quoted, and one that names none is a decision brought to him before it
is a line of the plan. An issue of the plan itself, the epic or one of its phases, is not that
issue: the design notes of the Lua to eBPF compiler made phase 6 compile the SNI parser of
`examples/filter` whole, and phase 5 build strings for it, a goal that only #879 and #880, the
issues of those two phases, asked for, and that the plan carried for two months, until the
maintainer read it: "isso foi um escape grave de dimensao" (#2567).

Code another project wrote is reused, not copied. A function that still follows another's method names
it in a note of one line above it, `/* based on math_random() @ lua/lmathlib.c */` in Lunatik's
`lib/lualinux.c`, `-- based on bpf_core_calc_field_relo() @ tools/lib/bpf/relo_core.c` in the compiler's
`vmlinux.lua`; the copyright lines of a header name who wrote the file, and a third party's does not go
there. #2347 first copied the loop of `project()` into `lib/lualinux.c` under no note, and its fixup then
put Lua.org's copyright on the whole file.

Reshaping or renaming an API means updating every consumer, grepped for — including consumers in
stacked or sibling pull requests that will rebase onto the change. A caller left on the old shape
compiles against a Lua module and only fails when its code path runs. The grep is taken on the
branch's own base when the change is written, not from a read made earlier in the session.

The same holds for a value, not only a name. A change that keeps its own copy of something another
field carries, because the kernel rewrites the original, has decided the two can differ:
`luaprobe_t` keeps the address the script gave in `requested` because `register_kprobe` rewrites
`kp.addr`, on x86 with IBT past the ENDBR. From then on every reader of the original is a decision,
which of the two it wants. Grep the readers of what the change
duplicates and settle each one, and read an architecture the host cannot run for every use, not only
the one the diff touches.

The kernel a consumer builds on bounds what a change may use, and not every consumer sits inside
the range this file declares: a product built on Lunatik can ship on an older vendor kernel. An API newer than a known consumer's kernel is a decision taken here, with the floor it sets
named, not one discovered at that consumer's build.

* Do not land an implementation you already intend to replace. A guarantee that holds only on some
  paths is not a guarantee: make it structural or do not offer it. Merging a half measure and opening
  a follow up that deletes it pollutes the history across pull requests the same way a commit that
  undoes another one pollutes a branch.
* Removing a check as redundant is verified, not asserted: trace the invariant to whoever establishes
  it and confirm every path that sets the value does.
* A function's contract — that it only reads, that it never sleeps, what it returns — is read from its
  body, not inferred from its name or its place in a method table. `connmark` reads and writes through
  one overloaded method despite sitting among read-only accessors; calling it read-only from where it
  sits is a guess, not a trace.
* Refusing is a legitimate outcome. When a combination has no sound semantics yet, refuse it where it
  is registered, with an error that names the reason, rather than shipping an approximation. Lifting
  the refusal afterwards is one line and a test. The reason is written where the refusal is made, so
  the change that removes it finds the refusal and lifts it.
* A decision taken with the maintainer is not reversed alone. When the investigation that follows points
  the other way, that is a question to bring back, not a conclusion to announce. Bring the finding, say what it would change, and wait.
* A step the session can take it takes. One only the maintainer can, a command the session's
  permissions refuse or his own terminal must run, reaches him as a script the session writes under
  `/tmp` and the one short line that runs it, `! bash /tmp/<name>.sh` in Claude Code: a command spelled
  out in the reply is one he copies by hand, and the terminal wraps it where the copy breaks.
  `tools/checks/handoff.sh` names a reply that hands him one. A write to GitHub is not such a step: the
  auto mode classifier reads the conversation for his go, so a post it refuses is shown again with
  the question whether to post, and posted on his answer. The writes an implement-issue run returns,
  its pull request's label, the groomer's `Update:` and the issues its filing prepared, are posted as
  the run returns and never brought back as a question: the maintainer ordered them posted always, "e
  sempre grave", after a session had asked him about four of them. One the classifier refuses is
  reported in the hand-back with the file that holds it. `tools/checks/settled.sh` names a decision
  that asks whether to post one.
* A question from the maintainer is answered, and the turn changes nothing: what the answer
  recommends is proposed with its decision, not done. "What is left?" asks for the list, not for the
  work on it; `.claude/hooks/on-prompt.sh` reminds a turn that reads a question. A message that ends
  in a question mark is a question whatever the text before it directs: "...; entendido?" asks
  whether the order was understood, and the turn says what it would do and waits for the go. #1865
  read one as an order, and the change it filed closed unmerged.
* A fact the maintainer states is taken as given and acted on, not verified back: "#736 is merged"
  ends a question rather than opening one, and re-arguing the point it settles spends the exchange
  on what is already decided. A state you assert yourself is the other way round, and *Verify, do not
  assume* governs it: read it before writing it.
* A call the conventions here already settle is made, not escalated: decide it, note it in a line, and
  move on. A question is for a genuine fork — where the answer changes the outcome and no rule,
  precedent, or test resolves it. Asking whether to add a comment the tree's macros never carry spends
  the maintainer on a call this document already made.
* "The tree does it" is a fact about the tree, not a reason. A choice is defended by what it buys and
  what it costs; prevalence says whether it is common, never whether it is right, and a tree can be
  wrong in a hundred places. When the only support for a line is a precedent, say so and judge it
  again.
* A need a consumer states is met first in that consumer's own code, over the API it already holds:
  the tree takes it only where that code cannot meet it, traced, and the shape that changes nothing
  here is the first one weighed, before anything is built or measured. That other embeddings carry an
  answer to the same need makes it common, not this tree's. #2442 asked the core to bound the work of
  a runtime's callback for an embedding that bounds it with a count hook in its own Lua, where each
  escape the core would have closed has a fix over the Lua that embedding holds; its groomer spent
  three hours and 337k tokens measuring the VM, proposed two lines of the fork that gave it new
  behaviour, and the maintainer had to ask twice what the core bought before the issue closed.
* That nobody uses a route sets the priority of a limit it carries, never whether the limit is
  documented or whether its issue stays open: "nao usarmos nao eh merito para nao documentar ou nao
  manter em backlog, eh merito apenas para nao priorizarmos". A limit whose premise stands is written
  where the API states its contract, and its issue waits in the backlog; a close is for a premise that
  does not stand. The groomer of luainkernel/luaebpf#8, a `__le16`, `__le32` or `__le64` member read in
  kernel order on a big-endian kernel, found it standing and recommended a close, since no host, test
  or consumer reads such a member, and the maintainer had the limit written in `bpf.vmlinux.layout`'s
  doc instead.

## Patches and commits

* Small, auditable, incremental commits. Each one stands alone and adds value.
* A commit is one change and everything that change entails, even across modules: a new core check
  adopted by four bindings is one commit. It is staged by purpose, the files of that change named and
  `git diff --cached` read against the message, never the whole tree an edit left behind;
  `tools/checks/stage-guard.sh` refuses `git add -A` and its kin. Independent fixes are separate commits, even when a single
  review finding uncovered them all; the finding is the reviewer's unit, not the committer's.
* A change to a function is read against the whole function, not the lines it touches: re-read it
  and take the simplification the change enables. A guard left standing that the new shape made
  redundant — `!cond || check(cond)` where the call now sits inside `if (cond)` — is a partial fix.
* A change that removes the last reader of a value removes what was written for it, as the NUL
  terminator and its byte go with the last read of a key as a C string. For every read the diff removes, ask what was stored, sized or kept only for that
  read; `tools/checks/terminator.sh` names the NUL case.
* Read the commit before pushing it, not only the working tree: `git show` the diff that is about to
  be published. Instrumentation added while debugging — a `pr_err`, a hardcoded branch — is invisible
  in a passing test and lands in the pull request.
* After resolving a rebase or a merge, `git grep -n '^<<<<<<< '` before committing. `git add -A`
  stages a conflict marker without complaining, and `git rebase --continue` runs no pre-commit hook,
  so the markers reach the branch and surface far from the resolution.
* Change only what the task requires. Do not reformat untouched lines, do not move code, do not
  rename variables in passing. Compare `git diff` against `git diff -w` before committing to catch
  stray whitespace.
* No dead or unnecessary code. A branch that cannot execute — a nil check on a call that raises
  instead of returning nil — is noise that misstates the API's contract.
* No cosmetic changes inside a feature or fix commit, not even a blank line.
* Never remove an existing comment unless the change made it factually wrong.
* Restoring something that was removed puts it back exactly where and how it was.
* A pull request's title and body are written as the pr-prep skill says.
* A pull request that replaces another says so in the body, `Alternative to #N`, and the merge of
  the replacement closes #N in the same breath: one left open is a claim about the queue nobody made.
  `tools/pr-status.sh` marks an open pull request a merged body names that way as superseded and
  keeps it out of `--ready`.
* A mechanism of the harness that rests on a command an agent runs, a guard's record among them, is
  exercised under the auto mode the sessions run in before it merges: the classifier can refuse such
  a command, as it refused the reader's `body-read.sh --pass` on #2541's corrected body, and the guard
  then refused the session's post of a body its reader had passed.
* No session links or assistant footers in a commit or a pull request beyond the `Co-Authored-By`
  trailer. The project settings turn the link off; one that slipped in is removed with a reword.
* A root cause named in a commit body or a pull request rests on a captured stack or a source-traced
  chain, not a correlated log line or a plausible mechanism. Until it is traced it is a hypothesis,
  labelled as one; a fix may land on the observed behaviour without naming a cause it has not proven.
  A release note, a changelog or any summary derived from commits is held to the same rule against
  its source: read each commit and use its words.
* A pull request reaches the maintainer's first review squashed: until he has read it, a correction
  folds into the commit it corrects, `git commit --fixup=<hash>` and `git rebase -i --autosquash` at
  once, and the branch goes up with `--force-with-lease`. After his review, a correction is
  `git commit --fixup=<hash>`, not a standalone "address review comments" commit, so what changed
  since he read it is a commit of its own. Never fixup a commit that is already on `master`; that
  becomes a new commit on a new branch.
* A fixup after the maintainer's review is pushed as soon as it is made, onto the pull request's own
  branch. It adds a commit, so it
  fast-forwards the branch and moves nothing a reviewer already read; what waits for the maintainer is
  the squash, and a rewrite is said out loud. A fixup that lives only on the machine that wrote it is
  outside the review, and a cleared worktree or a reboot takes it; one that lives only on `review/<n>`
  is outside it too, since the pull request lists its own branch's commits and nothing else, and
  "the fixups are on the pull request" is said after `gh api repos/.../pulls/<n>/commits` lists them,
  not before. The same holds for work handed to a reviewing agent: telling it not to push leaves the
  push owed by whoever gave the instruction.
* Each comment the maintainer leaves on a pull request is answered on the pull request, an inline one
  in its thread and one of the conversation by a comment that quotes its first line outside a quote,
  with the fixup that meets it or the answer itself, as that fixup is pushed: an answer given in the
  session's chat is one the pull request does not carry. #2630's review asked whether the collector
  could be stopped in an `scx` callback, and the answer reached the chat alone.
  `tools/checks/unanswered.sh <pr>` names each comment no reply answers, and the pull request goes back
  to him only once it names none.
* Work an agent does for a workflow outlives the agent. Its branch is pushed at each commit, pull
  request or not, and what it measured and decided goes to a checkpoint file, a line per step, that
  the agent relaunched in its place reads before anything else; the workflow then resumes with the
  finished agents from its cache and the unfinished ones from their branch and checkpoint.
* If a branch adds something in one commit and removes it in another, the second is a fixup of the
  first.
* After squashing, re read the comments, the commit bodies and the identifiers so they describe the
  final state rather than the path taken. A name is a residue as easily as a sentence: a type renamed
  to tell it apart from a sibling keeps that name after the sibling goes, and then the noun tells it
  apart from nothing. For every name the branch introduces or changes, ask what it distinguishes from
  in the final tree, and whether master already had a name for the same thing;
  `tools/checks/rename-orphaned.sh` catches the typedef case, and `tools/checks/body-identifiers.sh`
  the paragraph that still explains a mechanism a folded fixup removed.
* Naming an existing literal is done by visiting every call site of what carries it: sweep for the
  function's callers or the field's users, not for the literal, which misses positional arguments.
* Changing the value of a field visits every reader of it, in the code and in the field's doc, and
  asks what each does with the value: `class->name` is the type name a type error quotes and the
  name every context error prints. A reader that merely compiles
  against the new value is not accounted for.
* A force-push that restructures a branch is not done until the pull request title and body are
  re-read against it. They describe the branch; a rewrite that drops or replaces a mechanism turns
  them into fiction the reviewer reads first.
* A report of a push names the ref it moved and, separately, what it was rebased onto. "Force-pushed
  onto current master" reads as the one thing nobody may do, and a reader who has to parse a sentence
  to find out whether `master` was rewritten has already been alarmed for nothing. Say which branch
  took the push; the base is a different clause.
* Do not commit directly to `master`.

## Reviewing your own change

The conventions in this document, in the `CONVENTIONS.md` a project keeps and in `.agents/rules/` are a checklist to run against your own diff before showing it, not
reference to reach for after a reviewer objects. Code shown without that pass makes the reader the
reviewer, and the deviations they then find — a prefix nothing else in the file uses, a comment on a
body the file leaves bare, a handle closed by hand where the file uses `<close>` — were already rules
here. The failure is not the missing rule; it is not running the ones that exist.

Before presenting a change to an existing file, read the file as the authority and measure the
addition against it — naming, comment density, idioms, resource handling, duplication — then prove
the behaviour on the operation in isolation, not a round trip that hides a partial result: `unload`
reaching zero, not `reload` returning to a full set. The pass covers the prose the change ships with,
too: after any rewrite or force-push, the commit message and the pull request body go through the
same review against the final code — a claim the code does not support, a mechanism the branch
dropped or a rationale its call sites contradict, is caught there, as *Patches and commits* requires.
Saying the prose matches is not the check; showing the claim-to-code mapping is. A change shown
without that pass is not done.

Before the hand-back, every function the diff touches is re-read whole, not by its changed lines:
a new branch is asked whether it is this function's job or its caller's, a condition with stack
juggling is asked whether it is a predicate helper, and a guard the new shape made redundant is
removed. The maintainer reading a function and finding it dirtier than before is the pass not run.

The hand-back lists each finding of your own review that the change does not apply, with the
reason. A finding dropped in silence is found again by the maintainer, who then doubts the whole
review; and "few sites" is not a reason against a rule that collapses a repeated pattern.

A review comment names a principle, not a token. Read the words as written, say which principle they
invoke, and fix that: a note that an `enum` is formatted inline asks for the formatting, not for a
`#define`, and changing both leaves the reviewer to undo one.

## Before opening a pull request

Beside what the project's AGENTS.md asks here, its build, its suite and its examples among it:

1. new tests are wired into their suite and described, and the hand-back carries the matrix the
   change is held to: for each guard or mechanism it adds, the operations by types by outcomes,
   each cell naming its test or saying why it is not covered. Wiring is what a check confirms; the
   matrix is what a rewrite inherits from the branch it replaces unless it is written down;
2. error paths audited: for each raise, everything already acquired is released;
3. commits are small, ordered, and none of them undoes another;
4. every helper the change introduces has a caller. A helper extracted to remove duplication but
   left unused, while the duplication it replaces still stands, is the refactor half-done. Grep the
   new symbols for a caller before sending.
5. the branch is handed back merge-ready, not as a working scratch: the session's commits grouped into
   a clean history that none of them undoes, nothing left to squash, the pull request title and body
   describing the final state. On a harness or docs pull request you author, tidy it before returning
   it, unasked — what comes back is reviewed and merged, not tidied first.
6. the simplification pass, before sending. For each helper, collection, loop, or mechanism the
   change adds, a registration path, an argument on an API, a name for a literal, name what it buys
   over the minimal shape — weighing the whole cost, not the line count at one call site.
   A loop that vanishes locally by generating a build-time list can add more surface than it removes
   (an extra argument, an emitted table, a file to keep in sync); prefer the ground truth the system
   already exposes — the kernel's own "Used by" list, a field already on the struct — over a structure
   invented to encode it, and keep a loop that is doing honest work. The same holds for a comment: one
   non-obvious reason, one line, at the site that needs it — not spread over two, not repeated wherever
   the feature is touched.

## Reviewing a pull request

The process is `.agents/skills/review-pr/process.md`, which the review-pr skill opens with.
