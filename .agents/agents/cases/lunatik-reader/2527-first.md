---
verdict: fail
source: >-
  luainkernel/lunatik#2527, the body it opened with on 2026-11-14, which the maintainer received
  with "vc me fez perder tempo; custa muito para mim iniciar o review humano em PRs com descricao
  ilegivel": its first sentence runs 86 words over a driver the change never reaches, it shows no
  code, and it speaks of the cell and the plan line its test kept.
---
In a tc callback `skb:checksum()` reads and writes the IP and TCP or UDP headers of a non-linear skb as if its head held them: where they lie in the skb's fragments, as a driver that hands frames up through `napi_gro_frags` leaves them, the sums land in unused room past the head's end and the packet keeps its old ones, and on 6.12 and later an skb with a fragment the kernel does not read trips a kernel warning and gets a check over the pseudo header alone.

With this change `checksum()` raises "skb is not linear" on such an skb in a tc callback before it reads the packet, as `resize()` and `copy()` do there, and its doc says so; a linear skb is summed as it is. In a netfilter hook the skb is linearized and unshared first, as #2355 left it, and a failed pull there now raises "skb is not linear", as in `data()` and `resize()`. The tc suite's nonlinear case already hands a callback the TCP segment `tcp_sendmsg` leaves non-linear and reads `data()`, `copy()` and `resize()` refusing it, so `checksum()` joins that result with no new stimulus and no new plan line, and #2484, which carries this commit first, keeps the cell in its rework of the case.

It costs `checksum()` of a non-linear skb in a tc callback, which no example calls. A script cannot have changed such a packet there, since `data()` and `resize()` refuse it, so only the eBPF program can have, and it keeps `bpf_l3_csum_replace` and `bpf_l4_csum_replace`, or pulls the skb with `bpf_skb_pull_data(skb, skb->len)` before `bpf_luatc_run`, after which `checksum()` sums it. The examples over the bindings this touches, examples/dnsblock, examples/dnsdoctor, examples/ifquarantine, examples/sniclassify and examples/tcpreject, were not run before this push: the build that follows runs each through its own setup and cleanup. `dnsdoctor` and `tcpreject` call `checksum()` in a netfilter hook, and `sniclassify`, the one that attaches a tc callback, does not call it.
Closes #2322
Closes #2478

