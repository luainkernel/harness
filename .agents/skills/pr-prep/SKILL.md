---
name: pr-prep
description: Prepare a branch for a pull request and draft its title and body. Use when a branch is ready for a PR or when asked for a PR title and description.
---

Run AGENTS.md, "Before opening a pull request" (every item), and write the pull request's title and
body as this skill says: the title is a subject, `<area>: <what changes for whoever uses it>`, and the
body says what and why, nothing the commits already say, with no "Test plan" section and no em dashes.
On top of it:

- A fix answers a finding a script using the API as documented reaches; one whose stimulus is a
  script out of contract (AGENTS.md, "Deciding what to change") closes as not a defect instead.
- When the documentation changed, run what the project's AGENTS.md, "Before opening a pull request",
  asks of it, and read its exit status.
- Compare `git diff` against `git diff -w` for stray whitespace; `bash tools/checks/pre-commit`
  covers the trailing blank line on staged files.
- `bash tools/checks/advisory.sh origin/master HEAD`, the heuristic checks of the harness and those the
  project's `.agents/harness.conf` names over the files and the commits of the branch, and
  `bash tools/checks/author-email.sh origin/master..HEAD` over it after any rebase or
  squash, which signs the result with the checkout's own identity.
- Fixup commits stay unsquashed unless squashing was explicitly requested; the maintainer
  reviews them before they are folded.
- Every function the diff touches is re-read whole before the hand-back: is a new branch this
  function's job or its caller's; is a condition with stack juggling a predicate helper; did the
  new shape leave a guard redundant.
- The hand-back lists the findings of your own review the change does not apply, each with its
  reason; none is dropped in silence.
- The hand-back names, for each mechanism the change adds, the smaller shape that was considered
  and why it was not taken; a fix whose smaller shape was never written down is not ready.
- The hand-back carries the test matrix: for each guard or mechanism the change adds, operations
  by types by outcomes, each cell with its test or the reason it is not covered. A refusal's matrix
  is the resource's, every route from Lua to the lock or the call it protects, found by grepping
  what acquires it, not the entry point's that showed the hang.
- A test that skips on a build without the fix, and the message it says `check_dmesg` reads, go
  through the project's `bash tools/checks/test-harness.sh`, where it has one; and the run with the fix absent is made and its
  failure read, not argued from the header.
- Every example that uses a binding the change touches is run through its own `setup.sh` and
  `cleanup.sh`, and the hand-back says of each whether it ran, only loaded, or was not run, and why;
  the list is the project's `bash tools/checks/examples-touched.sh` over the changed files, taken on the
  branch's base when the change is written, and its `bash tools/checks/examples-named.sh <body> <changed
  files>` fails a body that leaves one of them unnamed, which `pr-body-guard.sh` runs when the pull request
  opens. An example is named as `examples/<name>` or as `<name>` in backticks, "`dnsblock`,
  `dnsdoctor` ran", never as a bare word, which the check does not read.
- The body explains the change to a reviewer who has not read its issue, in four short paragraphs
  at most: the failure or the need in one plain sentence, what a script can do today and what
  breaks; what the change lets a script or a user do, shown, where it reaches one, by the code they
  write, in a fenced block that reads on its own, every name in it defined there; what changes from
  today, the hand-written stub it replaces or the refusal it lifts; and what it costs or needs, a
  kernel, a build step, a path that pays more. An example counts as no paragraph. How the problem was
  found, what was measured and what was tried belong in the commits, and so do the words of that work,
  a test's cells and plan lines, a fixup, a squash, the push, and so does the mechanism: the
  body says what a reader of the API meets, not how the code reaches it. #2202 opened on "the kfuncs
  ... are reachable from hand-written C stubs alone" and a paragraph on how the call lowers into
  the frame, and the maintainer could not tell what it was for until a program file handing UDP
  frames to a kernel script showed it. #2527's opened on one sentence of 86 words over a driver its
  change never reaches, showed no code, and spoke of the cell and the plan line its test kept, with
  every check passing it. `bash tools/checks/pr-body.sh <file> <changed files>` runs before posting
  it, and names a first sentence longer than any a merged body opened on, a change that reaches what a
  script writes or calls, under the paths the `api` key of the project's `.agents/harness.conf` names,
  with no fenced block and no sentence on why no script is shown, "Nothing a script calls changes",
  and the commits' words, a cell, a stimulus, a plan line, a fixup, a squash, "this push", in a change
  that is not the tests' or the harness's.
- A body the session posts, opening a pull request or editing one, is read first by a reader with none
  of the change's history, the `lunatik-reader` agent, which `review.js` runs with neither phase:

        Workflow({scriptPath: '<checkout>/<mount>/.agents/skills/review-pr/review.js',
              args: {pr: <N, or 0 before it opens>, branch: '<branch>', head: '<sha>', base: '<sha>',
                     scratch: '<absolute dir>', repo: '<checkout>', mount: '<mount>',
                     github: '<owner>/<name>', body: '<the text>', title: '<the title>',
                     reviewer: false, build: false}})

  It restates in one line what the title says changes, from the title alone, and in two lines what
  the pull request does and why, from the title and the body, and names each place it cannot follow,
  quoting the words and the rule. What goes out is `read.file`, once `read.passed`, under the title
  `read.title` holds, and the hand-back carries both restatements. `pr-body-guard.sh` refuses the session's
  post of a body no reader of its workflow runs passed, read from the reader's own transcript, the text
  as it stands, so a body edited after the read is read again; one `review.js` returned ready was read
  already. A change to this skill or to `.agents/agents/lunatik-reader.md` runs the reader's cases
  again before it merges, as `.agents/rules/checks.md` says of the reader.
- The title and every subject of the branch are one plain clause of about 60 characters at most,
  with no subordinate clause, "where", "so", "whose", "as ...", the why left to the body:
  `bash tools/checks/title.sh '<title>'` and
  `git log --format=%s origin/master..HEAD | bash tools/checks/title.sh` name one with no area, past
  the length or opening such a clause, and `pr-body-guard.sh` refuses the title the session posts.
- A pull request that finishes a phase of an epic carries `Closes #<phase issue>` on a line of its
  own, and one that finishes none says `#<epic>, which it does not close`: a body that only says it
  is part of the epic, or answers an issue, closes nothing when it merges, and `pr-body.sh` fails it.
- A push, forced or not, is a command of its own, after the rebase before it is read as finished
  in `git status`; chained after one that stopped on a conflict, it publishes the base as the branch.
- After any force-push, re-read the title and body against the branch as it now stands.
- Once open, the pull request takes the label `bash tools/complexity.sh <N>` prints, and after a push
  that changes its size, the one it prints then in place of the old (AGENTS.md, *Patches and commits*).
- A pull request on another pull request's branch opens as a draft (`-F draft=true`), which GitHub
  will not merge before its base; `stacked-guard.sh` refuses one that does not.

