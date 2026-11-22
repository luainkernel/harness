---
name: release
description: Cut a release: confirm its milestone, the suite and the CI on the cut commit, write the notes from the commits, draft and publish the release, rebuild the site and close the milestone. Use when asked to cut, draft or publish a release, or for its notes or its announcement.
---

AGENTS.md is the authority, *Patches and commits* for a summary derived from commits and *Comments
and the verdict* for text shown before it goes public; this card orders the steps Lunatik's v5.0 cut
ran, and the project's AGENTS.md names what is its own, where its tree declares the release, the name a
release takes, the suite and the site. `<owner>/<repo>` is the repository the checkout's origin names. The
cut is the commit the maintainer names, or master's tip when he names none, recorded by its full SHA:
every step reads that SHA, never a branch that moves under it.

# 1. The milestone

    gh api "repos/<owner>/<repo>/milestones?state=open" --jq '.[] | [.number, .title, .open_issues] | @tsv'
    gh api "repos/<owner>/<repo>/issues?state=open&milestone=none&labels=severity:%20<level>&per_page=100" \
        --jq '.[] | select(.pull_request | not) | .number'

The release's milestone has no open issue, and the second command prints nothing for `high` nor for
`medium`: every open issue of those severities is in the release or in a later milestone, by the
maintainer's word.

The cut declares the release it is tagged as, read at the cut where the project's AGENTS.md says its
tree declares it (`git show <sha>:<path>`). A cut that declares another release waits on the commit
that bumps it, as Lunatik's v5.1 did (#1882), and the suite of the next step runs on the cut that
carries it.

# 2. The suite on the cut

The whole suite runs on the cut, as the project's AGENTS.md says its suite runs. A pull request merged
after the run leaves it standing only when `git diff <tested> <cut>` is that pull request's patch alone,
its `git patch-id` equal to the merged pull request's, and the patch reaches nothing the build, the
install or the suite reads: every file it changes lies under `tools/checks/`, `.agents/`, `.claude/`,
`.github/`, the harness's mount or what the `unread` key of the project's `.agents/harness.conf` names,
or is `AGENTS.md`, or every line it changes elsewhere is a comment or a copyright header, a shebang
only moved and not changed. Anything else runs the suite again on the cut.

# 3. CI on the cut

    gh api repos/<owner>/<repo>/commits/<sha>/check-runs --jq '.check_runs[] | [.name, .status, .conclusion] | @tsv'

The runs read are the cut's own, not a pull request head's, which passed on a tree the merge then
changed. Every one completed with `success`, or the cut waits, unless the maintainer says to go on
without it, and then the report names the runs still in progress.

# 4. The notes

Written from each commit's own words since the previous release's tag, `git log --reverse <previous
tag>..<sha>`, under Highlights, Fixes, Before upgrading, Changes to existing APIs, Known issues and
Contributors. Each bullet names the pull request it was read from, `(#N)`, and says what that commit
says, not what its issue's title says: v5.0's first draft worded #1286 from its issue and called
every known issue documented while #1260 was not.

Known issues lists the open issues the release ships with, read from GitHub and not from memory, each
with what a script meets today. The notes promise nothing to come: not the API freeze, which stays
the project's own rule (Lunatik's `.agents/rules/api.md`), and not the release that fixes a known
issue. Contributors are the authors of the range, `git shortlog -sn <previous tag>..<sha>`, with their
handles, and the first contributions with their pull requests. The body ends with
`**Full Changelog**: https://github.com/<owner>/<repo>/compare/<previous tag>...<tag>`, and not with
the list of pull requests GitHub generates.

`release-body.sh` reads the notes before they are shown, and `pr-body-guard.sh` runs it on the write.

# 5. The draft

    jq -n --arg tag <tag> --arg sha <sha> --arg name "<the name the project gives a release> <tag>" --rawfile body <notes> \
        '{tag_name: $tag, target_commitish: $sha, name: $name, body: $body, draft: true}' > <release.json>
    gh api -X POST repos/<owner>/<repo>/releases --input <release.json> --jq '[.id, .html_url] | @tsv'

The tag does not exist until the release is published, when GitHub creates it on `target_commitish`:
before the POST, `gh api repos/<owner>/<repo>/releases/tags/<tag>` answers 404, so no release carries
it, and after it `git ls-remote <url> refs/tags/<tag>` prints nothing, so the draft made no tag.
A draft rewritten after the cut or the notes moved is patched with the whole object the POST sent,
`tag_name` included: v5.1's draft, patched with its new `target_commitish` and body alone, came back
named `untagged-…`.

The session publishes the draft once the suite and the CI on the cut passed:

    gh api -X PATCH repos/<owner>/<repo>/releases/<id> -f tag_name=<tag> -F draft=false -f make_latest=true

The notes go to the maintainer whole, in the message that reports the release. On 2026-11-22 a session
handed him the draft to publish, and he answered "correcao, vc que publica, nao eu".

# 6. The site

A project that publishes a site rebuilds it on the release, as its AGENTS.md says: the workflow that
builds it runs on the `release` event, and its run is read by the cut's SHA. One that failed or was
cancelled, behind a push to master in the same concurrency group, is replaced by a dispatch, which builds
the same site:

    gh api "repos/<owner>/<repo>/actions/workflows/<workflow>/runs?event=release&head_sha=<cut>" \
        --jq '.workflow_runs[] | select(.head_sha == "<cut>") | [.id, .status, .conclusion] | @tsv'
    gh api -X POST repos/<owner>/<repo>/actions/workflows/<workflow>/dispatches -f ref=master

The deployed pages are read for the release they name, not taken from the run's success.

# 7. The milestone closes

    gh api -X PATCH repos/<owner>/<repo>/milestones/<number> -f state=closed

# 8. The announcement

Written only when the maintainer asks, as a prompt he hands on for LinkedIn and for lua-l: its facts
come from the published notes, the README and the repository's own record, each one read, and nowhere
else; it promises nothing to come, as the notes do not, and the lua-l post is plain text under
`[ANN] <the release's name> released`.

