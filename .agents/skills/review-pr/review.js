/*
* SPDX-FileCopyrightText: (c) 2026 Ring Zero Desenvolvimento de Software LTDA
* SPDX-License-Identifier: MIT OR GPL-2.0-only
*/

// A review as a workflow in two phases, each short enough to survive a provider error and resumable
// from the cache when one does not: a reviewer that reads the change once, through the packet the
// machine gathers for it or, past a head the maintainer read, what git shows moved, and a build that
// runs the host only when tools/checks/functional.sh names a file it reads past the validated head, or
// past the base where none was, or an example the change touches was not run on the validated head.
// Between them a reader with none of the change's history, the lunatik-reader agent, reads the title
// and the body the run returns, and a writer rewrites the ones it fails on its problems before it reads
// them again.
//
// Every phase appends what it finds to a checkpoint file the moment it finds it, so a phase that
// dies leaves its findings on disk and its successor continues from them instead of reading the
// branch again.
//
// Usage: Workflow({scriptPath: '.agents/skills/review-pr/review.js', args: {...}})
//   pr          the pull request, or 0 for a branch none opened yet, which has no conversation to read
//   branch      the author's branch, fetched and pushed by name
//   head, base  the head to review and the base it sits on, as full or short SHAs
//   scratch     an absolute directory for worktrees and the checkpoint
//   validated   {suite: "pass:N fail:0 skip:0", core: "<srcversion>", examples: [...]} when the exact
//               head already passed the suite, with the examples run on it through
//               tools/watchdog.sh, or null to build and run it here when functional.sh
//               names a file of the branch
//   examples    the examples the change touches, as tools/checks/examples-touched.sh lists
//               them over the changed files; the build phase runs whichever of them
//               validated does not carry
//   defects     [{patch, suite, fails, requirement}], the defect each new test is for, or each requirement
//               of the issue, as implement-issue's implementer writes them; the build plants each once
//               the suite passed
//   focus       what this round is for, in the maintainer's words
//   reviewed    the head the maintainer read, when head is a rebase or a split of it meant to change no
//               content: the reviewer reads the range-diff of that head against head and the files both
//               the branch and the base's new commits touch, in place of the packet, and nothing else
//   issue       the issue the change answers, whose requirements the review holds the final diff to;
//               a pull request's are the issues its body closes
//   update      the Update: a groomer settled for that issue, which binds as the issue does and
//               reaches it only once the run that launched the review returns
//   cases       [{suite, case}], the cases the change adds or changes, as the test prints them;
//               the build answers the line the suite printed for each
//   smallest    the implementer's smallest shape, when implement-issue launches the review
//   body        the body a branch with no pull request yet opens with, which the reviewer answers
//               corrected against the final diff, a reader with none of its history reads, and the
//               build reads for what it claims of the examples
//   title       the title it opens with, which the reviewer answers corrected as the body, and the
//               reader reads in its prompt, before the body
//   reads       how many times the reader reads the title and the body, a writer rewriting them between two reads,
//               default 3; 1 for a case of the reader, whose verdict is the first read's
//   reviewer    false to run the build phase alone, as implement-issue does after a fix, and with build
//               false too the reader of body alone, as the pr-prep skill runs it on a body the session posts
//   effort      the reviewer's reasoning effort, default "high"
//   model       the model the reviewer runs on, default the session's
//   agents      {model, effort} for each phase's agent, under review and build: review's over effort
//               and model, build's over its agent's definition, sonnet at medium effort; build's type
//               is the agent the build runs in, default lunatik-host, whose definition runs Lunatik's
//               cycle, so a project built another way names its own
//   push        false where a push from an agent is refused on this machine, so a fixup stays a
//               commit on review-<name>-<pr>-fixups and the session that launched the review pushes it
//   repo        the checkout the phases work in, default the repository they start in
//   machine     how this machine gets root and authenticates gh, for the build phase, whose agent
//               loads no CLAUDE.local.md; the launching session copies it from there
//   gh          false where the gh CLI is absent, so the REST calls go through curl
//   github      the repository on GitHub, owner/name; required, since the threads are read and the
//               checkpoints named by it. A repository that carries no packet of its own is reviewed with
//               this tree's packet and its own build. What the review and the build do of the project's
//               own, its kernel readings, its contract, its build and its suite, they do as its AGENTS.md asks
//   mount       where the checkout mounts the harness, relative to its top, default its top, as a tree
//               that carries the harness there does; the harness's scripts below are read under it
//   packet      the script that writes the packet, default tools/review-packet.sh of the harness in the tree under
//               review; an absolute path to this tree's where that tree carries none
//   build       what the build phase runs instead of the project's build and suite, for a tree that
//               carries no harness, or false where nothing runs on the host
//   ceiling     the tokens of context past which tools/checks/ceiling-guard.sh stops the reviewer: it closes
//               the checkpoint and returns, and the same prompt is launched again for one that reads it
//               first; default none
//   replaces    the replaces key of the project's .agents/harness.conf as it spells it, the conventions
//               of CONVENTIONS.md it keeps its own in place of, since the runtime reads no file
//               (tools/checks/project.sh); default none, as in the harness's own checkout. Where it
//               names smallest, a mechanism past the smallest shape needs no source to stay
//
// It returns each phase's answer and findings_left, every finding a phase leaves as an issue,
// with a title and a body that can be filed as they stand, and read, the reader's last answer, with the
// file that holds the body it read, the title and the body it read and whether it passed.

export const meta = {
  name: 'review-pr',
  description: 'Review a pull request: read it for findings over the packet the machine gathers, build and run only if needed',
  phases: [{ title: 'Review' }, { title: 'Read' }, { title: 'Build' }],
}

const a = args
const agents = a.agents || {}
const effort = agents.review?.effort || a.effort || 'high'
const model = agents.review?.model || a.model ? { model: agents.review?.model || a.model } : {}
const builder = { effort: (agents.build || {}).effort || 'medium', ...((agents.build || {}).model ? { model: agents.build.model } : {}) }
if (!a.github) throw new Error('review-pr: args.github is required')
const github = a.github
// the harness's scripts, under the mount in the tree under review
const H = a.mount ? `${a.mount}/` : ''
const packetTool = a.packet || `${H}tools/review-packet.sh`
// the repositories that share the harness share no numbering, so a checkpoint carries the repository's name
const unit = a.pr ? `review-${github.split('/')[1]}-${a.pr}` : `review-${a.branch}`
const checkpoint = `${a.scratch}/${unit}/REVIEW.md`
const packet = `${a.scratch}/${unit}/packet.txt`
const bodyFile = `${a.scratch}/${unit}/body.md`
// the prompt is read by an agent with a shell, so the default resolves on the machine that runs it
const repo = a.repo || '$(git rev-parse --show-toplevel)'
// gh is not on every machine; the same REST call goes through curl where it is absent
const api = (path) => a.gh === false
  ? `curl -sS -H "Authorization: Bearer $GH_TOKEN" "https://api.github.com/${path}?per_page=100"`
  : `gh api --paginate ${path}`
const RELAUNCHES = 3
const keeps = (name) => !(a.replaces || '').split(/\s+/).includes(name)
// ceiling-guard.sh reads the ceiling and the checkpoint on this line of the prompt
const CEILING = a.ceiling ? `
CONTEXT CEILING: ${a.ceiling} tokens, checkpoint ${checkpoint}
Past that context ${H}tools/checks/ceiling-guard.sh refuses every call but your answer, one that names the
checkpoint and git: write in the checkpoint where you are, the worktree and what is left, commit and push the
fixups made, and answer with ceiling true, ready false and the rest as far as it stands; a reviewer launched in
your place reads the checkpoint first.
` : ''
// the answer of a reviewer the ceiling stopped, which a launch that names none never asks for
const STOPPED = a.ceiling ? { ceiling: { type: 'boolean', description: 'true when the context ceiling stopped you before the review was done; the checkpoint says where' } } : {}

// a push from an agent is refused on some machines, so the fixup stays a commit and its launcher pushes
const FIXUP = a.push === false
  ? `A finding you can fix ships as \`git commit --fixup=<the commit that introduced it>\` on the local
branch ${unit}-fixups, taken from \`${a.branch}\`. Push nothing: the session that launched this
review pushes, and your answer names every SHA it made.`
  : a.pr
  ? `A finding you can fix ships as \`git commit --fixup=<the commit that introduced it>\` in your own
worktree, detached at the head of \`${a.branch}\`, pushed as soon as made (\`git push origin HEAD:refs/heads/${a.branch}\`;
where \`origin\` is not writable from this machine, CLAUDE.local.md says how it pushes).`
  : `A finding you can fix is \`git commit --fixup=<the commit that introduced it>\` in your own worktree, detached at
\`${a.head}\`, folded into that commit before you return (\`git rebase -i --autosquash --keep-base ${a.base}\`, which keeps the
fork point, so a base that moved past it does not carry the branch onto it), since no pull request exists yet
and the maintainer's first review reads it squashed; push it with \`git push origin HEAD:refs/heads/${a.branch}
--force-with-lease=refs/heads/${a.branch}:<the head you started from>\` (where \`origin\` is not writable from
this machine, CLAUDE.local.md says how it pushes), and your answer's tip is the head after the fold.`

const COMMON = `
You are reviewing ${a.pr ? `pull request #${a.pr}` : `the branch \`${a.branch}\`, which has no pull request yet,`} of
${github}, in the checkout at \`${repo}\`: branch \`${a.branch}\`, head \`${a.head}\`, base \`${a.base}\`.

CHECKPOINT, before anything else: the file ${checkpoint} is the review's memory across phases and across
a phase that dies. If it exists, read it and continue from it; do not redo what it records. Append every
finding the moment you close it, one line each:
\`file:line | what | disposition\` where disposition is \`fixup <sha>\`, \`stays: <reason>\` or \`issue: <title>\`.
An \`issue:\` line is also an entry of your answer's findings_left, whose body can be filed as it stands: what
the code does and where, the trace, the fix where there is one; its severity is the label
${H}.agents/skills/review-pr/process.md "Findings" names, and its home the open issue it belongs to, where one exists.
Your final answer is assembled from that file, not the other way round, and goes back into it under a heading
for your phase before you return, so a death between your last tool call and the runner's record still leaves
the verdict on disk.

ENVIRONMENT:
- Work in a worktree of your own under ${a.scratch}/, created with an ABSOLUTE path
  (\`git -C ${repo} worktree add --detach <abs path> <ref>\`, then \`git submodule update --init\`),
  named ${unit}-<phase>. A worktree that has the branch checked out is the launching session's, with its
  work in progress, and no phase commits, rebases or checks out there. The worktrees, the stash, the
  device and the examples are shared, as AGENTS.md "Build, install, test" and the guards it describes say.
- GitHub reads go through \`${api('<path>')}\`. DO NOT POST ANYTHING TO GITHUB.
- A command the host's policy refuses is written in the checkpoint and not tried again.

${a.focus ? 'THIS ROUND, in the maintainer\'s words: ' + a.focus : ''}
`

// a requirement nobody held the diff to closes with the issue, met or not
const asked = a.issue ? `issue #${a.issue}` : a.pr ? 'each issue the pull request\'s body closes' : ''

const REVIEW = COMMON + `
PHASE: REVIEW. The process is ${H}.agents/skills/review-pr/process.md; read its "Findings" and "Fixups" first.
You read the kernel, the contract and the reference documents as the project's AGENTS.md asks.

Then, in your worktree at \`${a.head}\`, write the packet the machine gathers for you, and read it whole
before anything else: \`bash ${packetTool} ${a.base} ${a.head} > ${packet}\`. It carries the commits
with their bodies, the files, what every check says and the diff with each function it touches whole, so
open a file beyond it only for what it does not show: a caller, a sibling, the kernel. The rules for the
files you read load with them, from .agents/rules/.${a.pr ? `
Read the pull request's threads too (\`${api(`repos/${github}/pulls/${a.pr}/comments`)}\` and
\`${api(`repos/${github}/issues/${a.pr}/comments`)}\`), which record what the maintainer cares about,
and run ${H}tools/checks/pr-body.sh over its body and the files the change carries, and ${H}tools/checks/title.sh over its
title.` : ''}${asked ? `
The change answers ${asked}: read it and its comments${a.update ? `, and the Update the run appends to it, which
binds as the issue does: ${JSON.stringify(a.update)}` : ''}. Your answer's requirements holds the final diff to
each requirement it states and each point an Update: settles, quoted: how the diff meets it, and the case that
fails when the diff does not, or why no case can. One the diff meets otherwise than its words say, or in part,
differs, and goes back to the session as a decision, since an issue closed by a change that narrowed it closes
narrowed with nobody having decided. One no case can fail on is a missing test, a finding of its own: a case
that reads no dmesg line a sleep prints proves nothing of a requirement that nothing sleeps.` : ''}

Every line under "# Checks" is answered in the checkpoint: a fixup, or why the code stays; a line of
function-shape.sh with the function's jobs listed. Where a check complains about something master already does, say so with the evidence.

Read the fit before any mechanism alone, as ${H}.agents/skills/review-pr/process.md says of a fix: the module the
change lands in, whole, the rule of it the change makes hold, and each path of the defect's family with the
mechanism of the diff that holds it, or none. Mechanisms added one per path, each kept for a defect of its own, or
a path left to a later change, are a finding: the smallest shape that holds the rule on every path, shipped as the fixups
that replace what it subsumes, or the offer refused where no such shape exists. Your answer's fit is that reading of
the final diff, your fixups included.

Look for the smallest shape first: for every mechanism the diff adds (a registration path, a new API argument,
a helper, a name), write the smaller change that would leave the same defect unreachable and why it was not
taken${keeps('smallest') ? `; where correctness is equal and the shape is smaller, that is a finding, shipped as the fixup that
makes it` : ''}. Your answer's smallest is that reading of the whole diff: the smallest shape, its size beside the
diff's, and what each mechanism past it buys. Each one, the implementer's included, is kept or removed${keeps('smallest') ? `: it
stays only with a source, a defect the smallest shape leaves reachable, traced, or a need the issue or the
maintainer stated, quoted (CONVENTIONS.md, "Deciding what to change"), and one without is removed by a fixup and
answered removed` : ` as the project's AGENTS.md weighs it, one removed by a fixup and answered removed`}.${a.smallest ? `
The implementer's own reading, which yours is not bound by: ${JSON.stringify(a.smallest)}` : ''}${a.body && !a.pr ? `
The pull request opens with this body once the build passes; read it with the commit bodies, and your answer's
body is this text with what the final diff, your fixups included, makes untrue, or ${H}tools/checks/pr-body.sh names
over it and the files the change carries, corrected as ${H}.agents/skills/pr-prep/SKILL.md says a body is written, the
rest as it stands:
${JSON.stringify(a.body)}` : ''}${a.title && !a.pr ? `
It opens with the title ${JSON.stringify(a.title)}, and your answer's title is that one with what the final diff
makes untrue, or ${H}tools/checks/title.sh names, rewritten.` : ''}
For every read the diff removes, name what was stored, sized or kept only for that read. For every helper the
diff extracts from functions that existed, read each caller's steps against the checks the helper now makes, in
the order the old bodies ran them: a step one caller keeps around the helper's call is an argument the helper
lacks. Then residues of
the path: anything in the final diff that exists because of how the branch grew rather than because the final
shape needs it, names first, then comments, LDoc, commit bodies, the pull request body, READMEs and every
reference document the diff touches. Then what the change duplicates: a field that keeps its own copy of a
value another field carries, every reader of the original, and which of the two each one wants. Then
correctness:
for every raise, what is held and who releases it; every get against its put; the execution context of every
path; the teardown order. Then the matrix the change is held to, operation by type by outcome including the
successes, and what the tests prove.

Before a finding is written, read the code once more to refute it: one whose stimulus is out of the
contract the project's AGENTS.md states is dismissed, neither fixed nor left as an issue, and one the code
does not reach is dropped.

${FIXUP} Its SHA goes in the checkpoint line. Ask of each one whether the finding is answered by removing
rather than adding. A fixup that changes what the project builds must at least build clean before it leaves
your phase; the suite is the Build phase's.${(a.defects || []).length ? `

The Build phase plants each defect below over your tip, and a fixup over a line one carries leaves it unable to
apply. After your last fixup, run \`git apply --check <patch>\` of each over your tip; one that no longer
applies you write again at the same path, carrying the defect the old patch carries: edit the tree, see that
the project's build takes it, \`git diff > <patch>\`, then \`git apply -R <patch>\`, each a call of its own. Note
each one written again in the checkpoint.
${JSON.stringify(a.defects, null, 2)}` : ''}
`

// a head the maintainer read was reviewed whole, so a rebase or a split of it is read where it moved
const REREAD = COMMON + `
PHASE: REVIEW of a rebase or a split of \`${a.reviewed}\`, the head the maintainer read, which was reviewed
whole. In your worktree at \`${a.head}\`, where <old> is the base he read, \`git merge-base ${a.reviewed} ${a.base}\`,
read what moved, whole: \`git range-diff <old>..${a.reviewed} ${a.base}..${a.head}\`, and the files both the
branch and the base's new commits touch,
\`comm -12 <(git diff --name-only <old> ${a.base} | sort) <(git diff --name-only ${a.base} ${a.head} | sort)\`.
Read the hunks range-diff marks changed and, in each of
those files, where the branch's hunks meet the base's new code, \`git diff ${a.base} ${a.head} -- <file>\`, and
nothing else: no packet, no thread, no issue. Your answer's fit, smallest, coverage and requirements answer what
those show alone, and its findings what they show wrong, a conflict resolved into other code, a commit that no
longer stands alone, a message the move made untrue. A commit range-diff marks \`<\` and pairs with none left
the branch: the new base carries it when a pull request below merged, as \`git log --oneline <old>..${a.base}\`
shows, and the move dropped it otherwise.

${FIXUP} Its SHA goes in the checkpoint line.
`

const unrun = (a.examples || []).filter(e => !(a.validated?.examples || []).includes(e))
const since = a.validated ? a.head : a.base
// functional.sh says what this tree's suite reads, not what a build of another tree or of a tool does
const asks = typeof a.build !== 'string' && (!a.validated || !unrun.length)

const BUILD = (tip, body) => `
PHASE: BUILD of ${a.pr ? `pull request #${a.pr}` : `the branch \`${a.branch}\``} of ${github}, in the checkout at \`${repo}\`.
${a.machine ? 'THIS MACHINE: ' + a.machine : 'Root commands run as `sudo <cmd>`; confirm that works without a prompt (`sudo -n true`) and, where it does not, skip the build and say so.'}

In a worktree of your own under ${a.scratch}/ at \`${tip}\`, the tip of \`${a.branch}\` with every fixup
(\`git -C ${repo} worktree add --detach <abs path> ${tip}\`, then \`git submodule update --init\`): ${typeof a.build === 'string' ? `${a.build}
Your answer's clean says whether that run passed.` : `the build clean, then the install, the reload and the whole suite through ${H}tools/lunatik-host,
as the project's AGENTS.md asks them, which you read in your worktree, since you load no CLAUDE.md, then the
examples the change touches through ${H}tools/watchdog.sh, each one driven as its README says and stopped, with
dmesg read after; a test that fails is reported with what ${H}tools/journal.sh prints around its line.`}
Your answer's kernel is what \`uname -srm\` prints here.${(a.cases || []).length ? ` Its cases holds, for each case below,
the line the suite printed for it, copied as printed, \`ok\`, \`not ok\` or a \`# SKIP\` with its reason: a case
that skipped proved nothing on this host, whatever the totals say.
${JSON.stringify(a.cases, null, 2)}` : ''}
${(a.examples || []).length ? `The examples the change touches: ${a.examples.join(', ')}. Your answer's examples names
the ones that ran clean, driven until they did what their README shows, spelled as they are listed here; one
that only loaded and stopped, or could not run on this host, goes in loaded instead, with why.` : 'The change touches no example.'}
${unrun.length ? 'These have not been run on this head: ' + unrun.join(', ') + '.' : ''}
${body ? `The pull request opens with the body below once this build passes. After the examples, read what its
sentence on them claims against what you ran: each claim you did not make, a mode, a command, a query, an
outcome, goes in your answer's unmet, with why: not run, could not run on this host, or ran and showed something
else. Run nothing past what the README drives; the difference is reported. A build that skips answers none.
${JSON.stringify(body)}` : ''}
${(a.defects || []).length ? `Once the suite passed, plant each defect below in turn, to watch the test it is for
fail: \`git apply <patch>\` in a call of its own, so the project's crash-guard.sh, where it has one,
reads the tree it leaves, then the build, and only when it builds the install, the reload and the run of that
suite through ${H}tools/lunatik-host; the cases it names
should fail, and no other, or, for one that names a requirement, at least one of them and no other, since a report
the kernel rate-limits, \`might_sleep()\`'s, lands in whichever case reaches the path first. \`git apply -R <patch>\`, in a call of its own, reverts it before the next. After the
last, build, install and reload the tip again and run those suites once more. A patch \`git apply\` refuses
plants nothing and answers applied false with failed empty; it and a call a guard refuses are reported, not
tried another way. Your answer's discrimination says, for each patch, whether it applied and the cases that
failed.
${JSON.stringify(a.defects, null, 2)}` : ''}
${asks ? `Before any of that: ${a.validated ? `\`${a.head}\` already passed (${a.validated.suite}, core ${a.validated.core}),
so ask what the branch changed since` : 'no head of this branch was validated, so ask what it changed from its base'} in
what the host reads, \`(cd ${repo} && bash ${H}tools/checks/functional.sh ${since} ${tip})\`. When it names nothing, comments,
spacing, documents or the harness alone having moved, run nothing, the examples included: answer skipped true, with
the tip as head, ${a.validated ? 'the validated totals and core' : `totals and core empty, since nothing was measured,
clean true`}, and in notes \`${since}\` and what \`git diff --name-only ${since} ${tip}\` lists.` : ''}
Remove your worktree when you are done (\`rm -rf <tree> && git -C ${repo} worktree prune\`), and nothing else
under ${a.scratch}/, which holds every phase's checkpoints and defect patches.
`

const READ = (title, text) => `
The body of ${a.pr ? `pull request #${a.pr}` : `the pull request the branch \`${a.branch}\` opens`} on ${github} is
the file ${bodyFile}, which you write first with your Write tool, exactly as this text: ${JSON.stringify(text)}.${title ? `
Its title is ${JSON.stringify(title)}.` : ''}
The checkout is at \`${repo}\`; the rules a title and a body are held to are
\`${repo}/${H}.agents/skills/pr-prep/SKILL.md\`.
`

const READ_OUT = { type: 'object', properties: {
  title: { type: 'string', description: 'what the title says changes and for whom, in one line, from the title alone; empty when none was handed' },
  restated: { type: 'string', description: 'what the pull request does and why, in two lines, from the title and the body alone' },
  problems: { type: 'array', items: { type: 'object', properties: {
    quote: { type: 'string' }, rule: { type: 'string' }, why: { type: 'string' },
  }, required: ['quote', 'rule', 'why'] } },
  remarks: { type: 'array', description: 'what else you would rather not read, which fails nothing', items: { type: 'object', properties: {
    quote: { type: 'string' }, why: { type: 'string' },
  }, required: ['quote', 'why'] } },
  verdict: { type: 'string', enum: ['pass', 'fail'] },
}, required: ['title', 'restated', 'problems', 'remarks', 'verdict'] }

const WRITE = (tip, title, text, problems) => `
The pull request ${a.pr ? `#${a.pr}` : `the branch \`${a.branch}\` opens`} on ${github} goes out with the title and the
body below, and a reader with none of the change's history failed them on the problems below, each quoting the words
it could not follow and the rule it holds them to. The change is the branch \`${a.branch}\` at \`${tip}\` over
\`${a.base}\`, in the checkout at \`${repo}\`: read its commits, \`git -C ${repo} log ${a.base}..${tip}\`, and the files
of its diff, \`git -C ${repo} diff --name-only ${a.base}...${tip}\`, each as \`git -C ${repo} show ${tip}:<file>\`, and the
rules a title and a body are held to, \`${repo}/${H}.agents/skills/pr-prep/SKILL.md\`.

Rewrite what each problem quotes so that the reader can follow it and its rule holds, true to the change as its commits
and its diff show it, and keep the rest as it stands, the issues it closes and what it says of each example among it.
Write the body to a file of your own under ${a.scratch}/ and run, in \`${repo}\`, \`bash ${H}tools/checks/pr-body.sh <file>
<the files that diff lists>\`${title ? ` and \`bash ${H}tools/checks/title.sh '<title>'\`` : ''}, and rewrite what they name.
Change nothing in the checkout and write nothing to GitHub. Your answer is the title, empty where none is given, and the
body.
${title ? `Title: ${JSON.stringify(title)}
` : ''}Body: ${JSON.stringify(text)}
Problems: ${JSON.stringify(problems, null, 2)}
`

const WRITE_OUT = { type: 'object', properties: {
  title: { type: 'string' }, body: { type: 'string' },
}, required: ['title', 'body'] }

const LEFT = { type: 'array', items: { type: 'object', properties: {
  title: { type: 'string' }, body: { type: 'string' }, severity: { type: 'string', enum: ['high', 'medium', 'low'] },
  contract: { type: 'string', description: 'what the documentation promises for the stimulus, quoted with its file, or "undocumented"; the severity is read against it' },
  home: { type: 'integer', description: 'the open issue this finding belongs to' },
}, required: ['title', 'body', 'severity', 'contract'] } }

const SMALLEST = { type: 'object', properties: {
  shape: { type: 'string', description: 'the smallest change that makes the defect unreachable, or meets the need' },
  lines: { type: 'integer', description: 'the lines that change adds and removes' },
  diff: { type: 'integer', description: 'the lines the pull request adds and removes' },
  beyond: { type: 'array', items: { type: 'object', properties: {
    mechanism: { type: 'string' }, buys: { type: 'string', description: 'what it buys that the smallest shape does not' },
    source: { type: 'string', description: 'the defect the smallest shape leaves reachable, with its trace, or the need the issue or the maintainer stated, quoted with where; empty when it has neither' },
    verdict: { type: 'string', enum: ['kept', 'removed'], description: keeps('smallest') ? 'removed by a fixup when it has no source' : 'removed by a fixup' },
  }, required: ['mechanism', 'buys', 'source', 'verdict'] } },
}, required: ['shape', 'lines', 'diff', 'beyond'] }

const FIT = { type: 'object', properties: {
  rule: { type: 'string', description: 'the rule of the module the change makes hold, one invariant in a line' },
  paths: { type: 'array', items: { type: 'object', properties: {
    path: { type: 'string', description: 'a path of the defect\'s family the module has' },
    held: { type: 'string', description: 'the mechanism of the diff that holds it, where the change refuses it, or none' },
  }, required: ['path', 'held'] } },
  whole: { type: 'boolean', description: 'true when one shape holds the rule on every path, the refused ones refused where they are registered' },
}, required: ['rule', 'paths', 'whole'] }

const FINDINGS = {
  type: 'object',
  properties: {
    ready: { type: 'boolean' },
    findings: { type: 'array', items: { type: 'object', properties: {
      file: { type: 'string' }, line: { type: 'integer' }, what: { type: 'string' }, disposition: { type: 'string' },
    }, required: ['file', 'what', 'disposition'] } },
    fixups: { type: 'array', items: { type: 'string' } },
    tip: { type: 'string', description: 'the full SHA of the branch tip after every fixup' },
    coverage: { type: 'string', description: 'the matrix the change is held to, and what nothing on this kernel can see' },
    requirements: { type: 'array', items: { type: 'object', properties: {
      requirement: { type: 'string', description: 'the requirement, or the point of an Update:, quoted with where it is stated' },
      how: { type: 'string', description: 'how the final diff meets it, with file:line' },
      case: { type: 'string', description: 'the case that fails when the diff does not meet it, as the test prints it, or why none can' },
      verdict: { type: 'string', enum: ['met', 'differs'], description: 'differs when the diff meets it otherwise than its words, or in part' },
    }, required: ['requirement', 'how', 'case', 'verdict'] }, description: 'empty when the change answers no issue' },
    fit: FIT,
    smallest: SMALLEST,
    body: { type: 'string', description: 'the body the pull request opens with, when one was handed to correct' },
    title: { type: 'string', description: 'the title the pull request opens with, when one was handed to correct' },
    findings_left: LEFT,
    notes: { type: 'string' },
    ...STOPPED,
  },
  required: ['ready', 'findings', 'fixups', 'tip', 'coverage', 'requirements', 'fit', 'smallest', 'findings_left', 'notes'],
}

const BUILD_OUT = {
  type: 'object',
  properties: {
    totals: { type: 'string' }, core: { type: 'string' }, head: { type: 'string' },
    skipped: { type: 'boolean', description: 'true when functional.sh named nothing past the validated head, or past the base where none was' },
    examples: { type: 'array', items: { type: 'string' } }, clean: { type: 'boolean' }, notes: { type: 'string' },
    kernel: { type: 'string', description: 'what uname -srm prints on the host the build ran on' },
    cases: { type: 'array', items: { type: 'object', properties: {
      suite: { type: 'string' }, case: { type: 'string' }, line: { type: 'string', description: 'the KTAP line the suite printed for it' },
    }, required: ['suite', 'case', 'line'] }, description: 'the line of each case handed, empty when none was or nothing ran' },
    loaded: { type: 'array', items: { type: 'object', properties: {
      example: { type: 'string' }, why: { type: 'string' },
    }, required: ['example', 'why'] }, description: 'the examples that only loaded and stopped, or could not run on this host' },
    unmet: { type: 'array', items: { type: 'object', properties: {
      example: { type: 'string' }, claim: { type: 'string' }, why: { type: 'string' },
    }, required: ['example', 'claim', 'why'] }, description: 'what the body handed claims of the examples that this run did not make' },
    discrimination: { type: 'array', items: { type: 'object', properties: {
      patch: { type: 'string' }, applied: { type: 'boolean', description: 'false when git apply refused the patch, which planted nothing' },
      failed: { type: 'array', items: { type: 'string' }, description: 'the cases that failed with the defect planted' },
      notes: { type: 'string' },
    }, required: ['patch', 'applied', 'failed'] } },
    findings_left: LEFT,
  },
  required: ['totals', 'core', 'head', 'clean', 'findings_left'],
}

let reviewer = null
if (a.reviewer !== false) {
  phase('Review')
  const prompt = (a.reviewed ? REREAD : REVIEW) + CEILING
  const options = { label: `review:${a.pr || a.branch}`, phase: 'Review', agentType: 'lunatik-reviewer', effort, schema: FINDINGS, ...model }
  reviewer = await agent(prompt, options)
  // a reviewer the ceiling stopped is launched again on its prompt, which reads the checkpoint first
  for (let n = 1; reviewer?.ceiling && n <= RELAUNCHES; n++)
    reviewer = await agent(prompt, { ...options, label: `${options.label}:${n + 1}` })
  if (reviewer?.ceiling) {
    log(`the reviewer stopped at the ceiling ${RELAUNCHES + 1} times; the session reads ${checkpoint}`)
    reviewer = null
  }
}

// the title and the body the run returns, the ones the reviewer corrected or, in a run of neither phase, the ones
// handed, are read by a reader with none of the change's history, and rewritten on what it fails them for
const handed = a.reviewer !== false ? !a.pr && (reviewer?.body || a.body) : a.build === false && a.body
const titled = a.reviewer !== false ? !a.pr && (reviewer?.title || a.title) : a.build === false && a.title
const tip = reviewer?.tip || a.head
let read = null
if (handed) {
  phase('Read')
  let title = titled || '', text = handed
  for (let n = 1; ; n++) {
    const answer = await agent(READ(title, text), {
      label: `read:${a.pr || a.branch}:${n}`, phase: 'Read', agentType: 'lunatik-reader', effort: 'high', schema: READ_OUT,
    })
    read = { passed: answer?.verdict === 'pass', file: bodyFile, title, body: text, answer }
    if (read.passed || !answer || n >= (a.reads || 3))
      break
    const written = await agent(WRITE(tip, title, text, answer.problems), {
      label: `write:${a.pr || a.branch}:${n}`, phase: 'Read', effort, schema: WRITE_OUT, ...model,
    })
    if (!written)
      break
    title = title && (written.title || title)
    text = written.body
  }
  if (!read.passed) {
    if (reviewer)
      reviewer.ready = false
    log(`not ready: the reader of the body names ${(read.answer?.problems || []).map(p => JSON.stringify(p.quote)).join(', ') || 'nothing it answered'}`)
  }
}

const changed = a.reviewer !== false && (!reviewer || reviewer.fixups.length > 0)
let build = null
if (a.build === false)
  log('build skipped: nothing runs on the host for this tree')
else if (!a.validated || changed || unrun.length) {
  phase('Build')
  build = await agent(BUILD(tip, !a.pr && (read?.body || reviewer?.body || a.body)), { label: `build:${a.pr || a.branch}`, phase: 'Build', agentType: agents.build?.type || 'lunatik-host', schema: BUILD_OUT, ...builder })
  if (build?.skipped)
    log(`build skipped: the branch moved past ${a.validated ? `${a.head}, validated,` : `its base ${a.base}`} only in what the build does not read`)
} else {
  log(`build skipped: head ${a.head} already validated (${a.validated.suite}, core ${a.validated.core}, examples ${(a.validated.examples || []).join(' ') || 'none'}) and no fixup changed it`)
}

const unsourced = !keeps('smallest') ? [] : (reviewer?.smallest?.beyond || []).filter(b => b.verdict === 'kept' && !(b.source || '').trim())
if (unsourced.length) {
  reviewer.ready = false
  log(`not ready: kept without a source: ${unsourced.map(b => b.mechanism).join('; ')}`)
}
if (reviewer?.fit && !reviewer.fit.whole) {
  reviewer.ready = false
  log(`not ready: no one shape holds ${reviewer.fit.rule}`)
}

const findings_left = [reviewer, build].flatMap(p => p?.findings_left || [])
return { checkpoint, reviewer, build, validated: build && !build.skipped ? null : a.validated, findings_left, unsourced, read }

