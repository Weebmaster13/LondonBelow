# Runtime Scheduler Validation

Validation rejects malformed ids, duplicate ids across one global namespace, unsupported schema types, unsupported schedule/queue/priority/budget/deadline/retry/window kinds, invalid references, self-dependencies, direct two-plan cycles, unsafe metadata/context/tags, Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized payloads, and deep payloads.

Forbidden scheduling, execution, RunService, task, coroutine, queue processing, retry, timeout, delay, dispatch, async, orchestration, startup, shutdown, initialization, dependency injection, service resolution, module loading, require-call, runtime API, gameplay, persistence, remote, client, Workspace, DataStore, HTTP, messaging, analytics, telemetry, Chapter, story, dialogue, cutscene, reference, callback, adapter, and runtime object fields reject anywhere in nested payloads.
