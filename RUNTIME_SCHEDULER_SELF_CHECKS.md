# Runtime Scheduler Self-Checks

`RuntimeSchedulerSelfChecks.lua` certifies Phase 39 before startup.

Self-checks prove malformed, duplicate, unsupported, unsafe, reference, forbidden-field, serialization, diagnostic sanitization, snapshot isolation, diagnostics isolation, bounded history, runtime limit, shutdown cleanup, global namespace, and no-execution behavior.

Self-checks are pre-start only and destructive. They are certification checks, not scheduling tooling.

## Hardened Proof Matrix

The self-check suite proves per-category rejection for live scheduling, task execution, RunService payloads, queue processing, runtime orchestration, frame scheduling, tick execution, live queue objects, dispatch execution, throttling execution, live performance mutation, timer execution, timeout execution, task.delay markers, coroutine markers, heartbeat markers, live time checks, execution gates, blocking execution, remediation, and scheduling execution.

It also proves forbidden markers reject in metadata, context, tags, nested tables, table keys, and string values; all category limits reject; every plan reference limit rejects; audit finding limits reject; diagnostics and snapshots are isolated; validation histories are bounded; and self-checks refuse after start.
