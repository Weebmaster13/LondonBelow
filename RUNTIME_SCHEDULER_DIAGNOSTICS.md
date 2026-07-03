# Runtime Scheduler Diagnostics

Diagnostics are health-only, not live scheduling.

Diagnostics expose lifecycle state, health, validation status, category counts, validation failure count, snapshot count, per-category limits, serialization posture, snapshot isolation proof, diagnostics isolation proof, scheduler/queue/budget/deadline/retry/interval/window/dependency/audit integrity posture, no-execution posture, recent sanitized validation failures, and the last self-check result.

Diagnostics do not contain live scheduled tasks, threads, coroutines, RunService, task handles, timer handles, live queues, dispatch state, service handles, Framework internals, module references, remotes, callbacks, execution adapters, or Workspace references.

## Hardened Diagnostic Proofs

Diagnostics include plan, slot, queue, priority, budget, deadline, retry, interval, window, dependency, audit, serialization, snapshot isolation, diagnostics isolation, and no-execution postures.

The no-execution posture explicitly proves no schedule execution, no task/job/coroutine execution, no RunService execution, no frame/tick/heartbeat/stepped/renderStepped scheduling, no queue processing, no retry/timeout/timer/delay/dispatch/async execution, no task.spawn/task.delay/task.defer, no wait/delay/spawn, and no runtime orchestration.
