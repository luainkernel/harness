---
verdict: pass
source: >-
  luainkernel/lunatik#2527, the body it merged with on 2026-11-14, written after his words on the
  first.
---
In a tc callback, `skb:checksum()` on a non-linear skb reads and writes the IP and TCP or UDP headers as if the skb's head held them: the new sums land in unused room past the head and the packet keeps its old ones, and on 6.12 and later a fragment the kernel cannot read also trips a kernel warning.

With this change the call raises "skb is not linear" there before it reads the packet, as `skb:data()`, `skb:resize()` and `skb:copy()` already do:

```Lua
local tc     = require("tc")
local action = require("linux.tc").action

local function resum(ctx)
	local skb = ctx:skb()
	local ok, err = pcall(skb.checksum, skb)
	-- on a non-linear skb, ok is false and err ends in "(skb is not linear)"
	return action.OK
end

tc.attach(resum)
```

A linear skb is summed as before. A netfilter hook still linearizes and unshares the skb before it sums it; only a pull that fails there now raises "skb is not linear" where it raised "skb is not writable", as `skb:data()` and `skb:resize()` do.

It costs `checksum()` of a non-linear skb in a tc callback, which no example calls. A script cannot have changed such a packet there, since `data()` and `resize()` refuse it, so only the eBPF program can have, and it keeps `bpf_l3_csum_replace` and `bpf_l4_csum_replace`, or pulls the skb with `bpf_skb_pull_data` before it calls `bpf_luatc_run`. `dnsdoctor` and `tcpreject`, which call `checksum()` from netfilter, and `dnsblock`, `ifquarantine` and `sniclassify` ran through their setup and cleanup on the build of #2484, which carries this `checksum()` unchanged.
Closes #2322
Closes #2478

