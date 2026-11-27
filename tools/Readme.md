# Additional tools

Each GitHub tool here reads the repository the checkout's `origin` names, and `issues.sh`,
`issue-since.sh` and `pr-status.sh` another one `LUNATIK_REPO` names.

## agent-review.sh

Sets the `agent-review` status `checks/merge-guard.sh` reads on a commit, and only where the record
of a review passed it: the newest review of it, or of a commit of its tree, that `review.js` ran at
`high` effort or above returned it ready, or, for a commit a merge put on the trunk, the pull request it
merged was reviewed so or merged on its proof (the merged skill, sections 0 and 5).

```sh
bash tools/agent-review.sh luainkernel/harness 1fdae56 <token file>    # agent-review: 1fdae56ae: review.js: ready, wf_1a941637-11a at high
```

## complexity.sh

Prints the `complexity:` label each pull request carries, by the lines it adds: up to 40 `small`, up to
150 `medium`, past that `large`. The maintainer picks what he reviews by it, the small first.

```sh
GH_TOKEN=... bash tools/complexity.sh 2340    # complexity: medium
```

## delete-branch.sh

Deletes a merged branch on GitHub, and only where its tip is the head the pull request merged with (the
merged skill, section 4).

```sh
bash tools/delete-branch.sh luainkernel/lunatik checks-held-edit-repo <token file>
# delete-branch: luainkernel/lunatik checks-held-edit-repo deleted at <tip>, the head #2440 merged with
```

## issues.sh

Reports the issues an epic tracks as GitHub has them: the epic and each issue whose body says it
is part of it, its state, and the pull requests whose body names it, with what each body does to
it. It flags an open issue a merged pull request names, and a merged pull request tied to an issue
in the words `pr-body.sh` reads that closes none.

```sh
GH_TOKEN=... bash tools/issues.sh 657     # the fsnotify epic and its phases
GH_TOKEN=... bash tools/issues.sh 1001    # one issue and the pull requests that name it
```

## issue-since.sh

Lists the commits master took since an issue was opened that touch the files the issue names, so an
issue the tree answered after it was filed is read as answered before an agent is launched on it. The
implement-issue skill runs it before each launch; the commits are read, not obeyed.

```sh
GH_TOKEN=... bash tools/issue-since.sh 2131    # names 097d27e13, which added the case the issue asks for
```

## merge.sh

Merges a pull request by rebase, its head named, only where `checks/merge-guard.sh` passes the merge,
and prints GitHub's answer, whose `sha` is the commit the merge put on the trunk (the merged skill,
sections 0 and 5).

```sh
bash tools/merge.sh luainkernel/harness 35 d743e120753d332e8be73475bd1119fb9f077f8a <token file>
# {"sha":"81daee218441d11a3140c796004901311f52985e","merged":true,"message":"Pull Request successfully merged"}
```

## oops.sh

Captures the last kernel oops before a reboot takes it away: the `dmesg` block, the instructions
around the faulting one in the installed module, and the processes left in D state.

```sh
tools/oops.sh > scratch/oops-$(date +%F).txt
```

A saved dump, `journalctl -k -b -1 -o cat` after the reboot where the journal is persistent,
is read the same way: `tools/oops.sh <dump>`.

## prereboot.sh

Saves what a reboot erases into `scratch/reboot-<time>/` of the checkout, for every session on the
host: the last oops, the Lunatik modules loaded with what holds them and the build they came from,
the processes in D state, and the files each session keeps under `/tmp`. The session that asks for
a reboot runs it first.

```sh
bash tools/prereboot.sh
```

## pr-status.sh

Reports the open pull requests as GitHub has them: base and mergeability, commits and unsquashed
fixups, size, CI conclusion and labels. `--ready` keeps the ones reviewed by a workflow, green on
CI, with no fixup pending and mergeable.

```sh
GH_TOKEN=... bash tools/pr-status.sh            # every open pull request
GH_TOKEN=... bash tools/pr-status.sh --ready    # what a maintainer can pick up
GH_TOKEN=... bash tools/pr-status.sh 814 822    # these ones
```

## retry.sh

Runs a command that reaches the network until it succeeds, a given number of times a given number of
seconds apart, so a CI job outlasts a mirror or a download that stops answering for a few minutes.

```sh
bash tools/retry.sh 5 90 sudo apt-get install -yq sparse
```

## usage.sh

Measures where the tokens go, from the transcripts and the run records Claude Code keeps for the
sessions started in the directory it runs in: by kind of run, by role, model and effort, the first
request of each agent type, the requests that wrote the cache again with what each waited on, and the
pull requests the runs opened. It prints sums and counts, never a transcript's text. Given runs, it
prints a line for each first, the one an implement-issue run's hand-back carries. Its baseline is
its tables over 2026-10-28 to 2026-11-26, the window luainkernel/harness#6 measured, posted in
https://github.com/luainkernel/harness/issues/6#issuecomment-7193630153.

```sh
bash tools/usage.sh --since 2026-11-27    # every run and session since that day
bash tools/usage.sh wf_fe988b09-8b6       # a run, its line first
```

## watchdog.sh

Runs a Lunatik script and stops it if the host loses the connectivity it had before the run,
the loopback or the default route's gateway; a script that cuts the machine off cannot be
stopped by hand afterwards.

```sh
sudo bash tools/watchdog.sh examples/ifquarantine/control
sudo LUNATIK_WATCHDOG_GRACE=10 bash tools/watchdog.sh examples/filter/sni --context=softirq --percpu
sudo bash tools/watchdog.sh examples/echod/daemon spawn  # a script that returns a thread body
```

