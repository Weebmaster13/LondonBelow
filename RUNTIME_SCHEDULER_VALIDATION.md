# Runtime Scheduler Validation

Validation rejects malformed ids, duplicate ids across one global namespace, unsupported schema types, unsupported schedule/queue/priority/budget/deadline/retry/window kinds, invalid references, self-dependencies, direct two-plan cycles, unsafe metadata/context/tags, Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized payloads, and deep payloads.

Forbidden scheduling, execution, RunService, task, coroutine, queue processing, retry, timeout, delay, dispatch, async, orchestration, startup, shutdown, initialization, dependency injection, service resolution, module loading, require-call, runtime API, gameplay, persistence, remote, client, Workspace, DataStore, HTTP, messaging, analytics, telemetry, Chapter, story, dialogue, cutscene, reference, callback, adapter, and runtime object fields reject anywhere in nested payloads.

## Production Hardening

Validation rejects live queue objects, dispatch state, timer execution, throttling execution, live performance mutation, live time checks, execution gates, blocking execution, task handles, timer handles, coroutine handles, RunService references, live scheduler handles, enforcement, remediation, coroutine create/resume markers, task.spawn/task.delay/task.defer markers, wait/delay/spawn markers, and every scheduler execution marker before state mutation.

Reference validation remains schema-only. It validates ids and direct relationships; it never checks live queues, live clocks, live frames, RunService, task APIs, or runtime services.
