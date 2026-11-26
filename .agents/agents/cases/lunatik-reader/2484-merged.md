---
verdict: pass
title: "skb: data() reads a non-linear skb in a tc callback"
source: >-
  luainkernel/lunatik#2484, the title the maintainer took on 2026-11-15 and the body it merged with
  that day.
---
In a tc callback `skb:data()` raises "skb is not linear" on a non-linear skb, and every TCP segment the host sends is one, its payload in page fragments. Today a callback reads that payload only if its eBPF program first pulls the whole skb with `bpf_skb_pull_data`, which linearizes it for the rest of the stack.

With this change the callback reads the segment as it came. This callback, in a softirq runtime whose tc program hands it each segment the host sends, unpulled, drops the ones whose payload opens a TLS handshake record:

```Lua
local tc     = require("tc")
local action = require("linux.tc").action

local ETH_HLEN  <const> = 14     -- the Ethernet header's length
local IPV4      <const> = 0x0800 -- ETH_P_IP
local TCP       <const> = 6      -- IPPROTO_TCP
local HANDSHAKE <const> = 0x16   -- the TLS record a ClientHello travels in

local function nohello(ctx)
	local p = ctx:skb():data()
	if (p:getbyte(12) << 8 | p:getbyte(13)) ~= IPV4 or p:getbyte(ETH_HLEN + 9) ~= TCP then
		return action.OK
	end
	local ip = (p:getbyte(ETH_HLEN) & 0x0f) * 4
	local payload = ETH_HLEN + ip + (p:getbyte(ETH_HLEN + ip + 12) >> 4) * 4
	if payload < #p and p:getbyte(payload) == HANDSHAKE then
		return action.SHOT
	end
	return action.OK
end

tc.attach(nohello)
```

In a tc callback, `skb:data()`, `skb:data("net")` and `skb:data("mac")` of a non-linear skb now return a read only view of a copy of the packet, to its end: the getters, `getstring`, `checksum` and `tostring` read it, and `setstring` and `resize` raise "read only". A linear skb keeps its view in place, and outside a tc callback `skb:data()` still linearizes. `skb:copy()`, `skb:resize()` and `skb:checksum()` still raise "skb is not linear" on a non-linear skb in a tc callback.

The copy is taken at the callback's first `skb:data()`, into a buffer each runtime keeps: it grows to the largest packet the runtime has seen, headroom included, up to 64 KiB with the default `gso_max_size`, and never shrinks. A buffer that cannot grow raises "not enough memory", and a fragment the kernel does not read, on 6.12 and later, raises `EFAULT`. Alternative to #2483; the compiled read #2190 asks for, which this does not close, is #2235, stacked on this branch. The examples over the bindings this touches ran, each through its own setup and cleanup: examples/dnsblock, examples/dnsdoctor, examples/ifquarantine, examples/sniclassify, whose `classify.c` still pulls the skb, and examples/tcpreject.

