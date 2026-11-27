# harness

What the projects that mount it share, Lunatik and luaebpf among them: the process of commits, pull
requests and review in `AGENTS.md`, the conventions of Lunatik and luaebpf past it, how a commit is
titled, how a decision is brought, what a pull request carries, who merges it and a file's header, in
`CONVENTIONS.md`, the rules for Lua, comments, tests and checks under `.agents/rules/`, the
workflows and agents under `.agents/`, the command guards and the checks under `tools/checks/`, the
tools of the host both run their suites on under `tools/`, and the Claude Code hooks under
`.claude/hooks/`. It was taken from luainkernel/lunatik at
db6e9860093655e0282f3b069fbc8a9e7c106de0, where the history of these files stays.

A project mounts it as a git submodule, `git submodule add https://github.com/luainkernel/harness
<mount>`, and then:

- its `CLAUDE.md` imports `<mount>/AGENTS.md` beside its own `AGENTS.md`, which points here and states
  the project's build, its suite, its kernel readings and its contract, which the prompts of the shared
  workflows name and do not restate, and `<mount>/CONVENTIONS.md` where it keeps those conventions in
  place of its own;
- its `.claude/settings.json` repeats the hooks of this one's under `<mount>/`, beside its own guards,
  and its `.claude/skills/`, `.claude/agents/` and `.claude/rules/` link into `<mount>/.agents/`;
- its `.agents/harness.conf` gives what the shared scripts read of it, the keys
  `tools/checks/project.sh` names, `replaces` among them, the conventions of `CONVENTIONS.md` it keeps
  its own in place of, whose checks it skips and whose steps the workflows it launches drop;
- it carries a `lunatik-cycle` skill, its host cycle, which the shared `lunatik-host` agent loads by
  name;
- its own checks, their cases and its own rules and skills live at the same paths of its tree, and
  `<mount>/tools/checks/cases.sh`, run from the mount, runs the cases of both;
- a change here reaches it as a pull request of its own that moves the mount (the merged skill).

A change to the harness is written and reviewed from a project's mount, in a session opened on that
project: this repository carries no `CLAUDE.md` and no `.claude/skills/`, `.claude/agents/` or
`.claude/rules/`, so a session opened here runs the guards of its `.claude/settings.json` and loads no
`AGENTS.md`, no skill and no agent type, the `lunatik-reader` and `lunatik-host` its review needs among
them.
