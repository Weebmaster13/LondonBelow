# Runtime Scheduler Serialization

Runtime Scheduler serialization protects schema state, diagnostics, and snapshots.

Authoritative records reject Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized node counts, and deep payloads. Diagnostic copies sanitize unsafe values, service references, remote references, runtime objects, callbacks, module references, Framework references, Workspace paths, RunService references, task handles, coroutine handles, live queues, live timers, live deadlines, and execution adapters.

Snapshots, diagnostics, and public exports are isolated deep copies.
