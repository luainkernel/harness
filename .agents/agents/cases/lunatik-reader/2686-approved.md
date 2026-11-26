---
verdict: pass
source: >-
  luainkernel/lunatik#2686, the body it opened with on 2026-11-19: the reader had failed five texts
  in a row of it, each time on points the last one had not raised, and the maintainer approved this
  one in his own words.
---
On a kernel built with PREEMPT_RT, freeing a Lua value larger than a page with interrupts off, from a kprobe handler or under a hardirq runtime's lock, can corrupt memory: the kernel writes to the value after it is freed (#2603).

Now `lunatik_defer(defer, finalize)` calls `finalize` on a kernel worker and touches `defer` no more once it does, so `finalize` may free the memory that holds `defer`:

```c
#include <linux/slab.h>

#include <lunatik.h>

typedef struct luafoo_request_s {
	lunatik_defer_t defer;
	void *buffer;
} luafoo_request_t;

/* runs on a kernel worker, in process context */
static void luafoo_finalize(lunatik_defer_t *defer)
{
	luafoo_request_t *request = container_of(defer, luafoo_request_t, defer);

	kvfree(request->buffer);
	kfree(request);
}

/* may run in softirq or hardirq context, or in a probe handler */
static void luafoo_drop(luafoo_request_t *request)
{
	lunatik_defer(&request->defer, luafoo_finalize);
}
```

The new call takes the place of three: `lunatik_initdefer(defer, func)` and the one-argument `lunatik_defer(defer)`, which queued `func` on a kernel worker, and `lunatik_syncdefer`, which `func` had to call before freeing the memory that held `defer`. No binding in the tree defers today; the core's own deferred frees, of objects and of large values, go through the new call, and that is what fixes #2603.

A `finalize` that sleeps delays the frees deferred after it, since they run one at a time. Nothing a script calls changes. `dropreason`, `echod`, `ifquarantine`, `netfailover`, `spyglass` and `systrack` were not run: the maintainer asked to review this change before it runs. Closes #2603.

