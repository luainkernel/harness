---
verdict: fail
source: >-
  luainkernel/lunatik#2202, the body it opened with on 2026-10-25, on the kfuncs reachable from
  hand-written C stubs alone and a paragraph on how the call lowers into the frame: the maintainer
  could not tell what it was for until a program file handing UDP frames to a kernel script showed
  it (harness/.agents/skills/pr-prep/SKILL.md).
---
A compiled program cannot defer a packet to Lua: `bpf_luaxdp_run` and `bpf_luatc_run`, the kfuncs that run a kernel Lua runtime's callback, are reachable from hand-written C stubs alone.

`xdp.runtime(name)` and `tc.runtime(name)` name a runtime by the script it runs, and a call to it in the program's own function lowers to the kfunc of the program's type, the name NUL-terminated in the frame and each argument a 64-bit word; the answer is a type the program tests with `if v then` or `v == nil`, nil where the kfunc returns -1, and any other read of it before the test is refused at its line. The object carries the kfunc as libbpf reads one out of a clang `__ksym` extern, and `lunatik bpf` prints a line per call it compiled. That is the smallest shape; past it, the frame's depth and its stack refusal move from `lower()` into `frame.lua`, so the call's words below the frame are held to the limit `lower()` already applies, which AGENTS.md asks of a mechanism a change would otherwise copy ("leaves two mechanisms doing one job"). `examples/sniclassify` stays C: an egress TCP segment is not linear, and #2190 asks for reading such an skb's bytes.

A program that calls a runtime needs the module's BTF (`make btf_install`); one that does not needs nothing new. Alternative to #947, which this merge closes.
Closes #878

