# Runtime Scheduler Serialization

Runtime Scheduler serialization protects schema state, diagnostics, and snapshots.

Authoritative records reject Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized node counts, and deep payloads. Diagnostic copies sanitize unsafe values, service references, remote references, runtime objects, callbacks, module references, Framework references, Workspace paths, RunService references, task handles, coroutine handles, live queues, live timers, live deadlines, and execution adapters.

Snapshots, diagnostics, and public exports are isolated deep copies.

## Hardened Serialization Boundary

Diagnostic copies must never preserve raw functions, threads, userdata, Instances, cycles, service references, remote references, runtime objects, callbacks, module references, Framework references, Workspace paths, RunService references, task handles, coroutine handles, timer handles, live queue objects, dispatch state, live scheduler handles, or execution adapters.

Serialization never creates timers, queues, tasks, coroutines, RunService hooks, or scheduler control data. It only validates and copies schema-safe data.
