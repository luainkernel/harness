---
verdict: pass
title: "luaebpf: compiled programs can call a kernel Lua script"
source: >-
  luainkernel/lunatik#2202, the title the maintainer took on 2026-11-15 and the body it merged with
  that day.
---
A program file that `lunatik bpf` compiles cannot hand a packet to a kernel Lua script: that takes an eBPF program written in C and built with clang, so a filter that needs a string, a table built at run time or a parser the compiler refuses is written in C, or left whole to a Lua callback that runs the interpreter on every packet.

With this, the program decides the common case itself and hands the rest to a kernel script. It names the runtime by the script that runs it, `lunatik.runtime("limits")`, and calls `limits:run(...)` with numbers, which the script's callback reads as 64-bit integers from `ctx:argument()`. The call answers the callback's verdict, or nil when no softirq runtime of that script is running or its callback raises or returns no verdict, and the program must test the answer before it uses it. Here UDP frames go to `limits.lua`, which drops a frame to port 53 longer than 512 bytes:

```Lua
-- ports.bpf.lua, the program file
local xdp     = require("bpf.xdp")
local lunatik = require("lunatik")
local action  = require("linux.xdp").action

local ETHERTYPE <const> = 12 -- offset of the EtherType, 0x0800 for IPv4
local PROTOCOL  <const> = 23 -- offset of the IPv4 protocol byte
local PORT      <const> = 36 -- offset of the UDP destination port, past an IPv4 header with no options
local UDP       <const> = 17

local limits = lunatik.runtime("limits")

return xdp.program(function(ctx)
	local p = ctx:packet()
	if p:getbyte(ETHERTYPE) ~= 0x08 or p:getbyte(ETHERTYPE + 1) ~= 0x00 or p:getbyte(PROTOCOL) ~= UDP then
		return action.PASS
	end
	local port = p:getbyte(PORT) << 8 | p:getbyte(PORT + 1)
	local verdict = limits:run(port, #p)
	if verdict then
		return verdict
	end
	return action.PASS
end)
```

```Lua
-- limits.lua, the kernel script
local xdp    = require("xdp")
local action = require("linux.xdp").action

local longest = {[53] = 512} -- the longest frame a port takes

xdp.attach(function(ctx)
	local argument = ctx:argument()
	local port, length = argument:getint64(0), argument:getint64(8)
	local limit = longest[port]
	if limit and length > limit then
		return action.DROP
	end
end)
```

```Shell
sudo install -m 0644 limits.lua /lib/modules/lua/limits.lua
sudo lunatik bpf -o /lib/modules/lua/ports.bpf.o ports.bpf.lua
sudo lunatik run --context=softirq limits
sudo lunatik run --dev=eth0 ports
```

What changes: the program needs no C and no clang, and a TC program calls a runtime the same way. `lunatik bpf` prints a line per call, `<file>:<line>: calls the runtime '<name>'`, so the author sees where the program leaves eBPF, and refuses at its line an answer used before it is tested, a call of the runtime itself and any method but `run`, each naming what to write. In the kernel modules only LDoc changes, in `lunatik_core.c` and `lunatik_percpu.c`, so `dropreason`, `echod`, `ifquarantine`, `netfailover`, `spyglass` and `systrack`, which `tools/checks/examples-touched.sh` lists for those files, were not run.

What it costs: each call runs the Lua interpreter on the packet path, paid only by the frames the program hands over. The object loads only where `luaxdp` or `luatc` was built after `sudo make btf_install`; elsewhere `lunatik run` reports libbpf's "not found in kernel or module BTFs" and attaches nothing. A directory given to `lunatik bpf --scripts` must now carry `linux/bpf.lua`, from which the compiler reads the eBPF stack limit a call's name and arguments must fit in. Alternative to #947, which this merge closes.
Closes #878

