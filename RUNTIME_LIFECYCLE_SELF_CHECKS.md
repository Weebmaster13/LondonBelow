# Runtime Lifecycle Self-Checks

`RuntimeLifecycleSelfChecks.lua` certifies Phase 38 before startup.

Self-checks prove malformed, duplicate, unsupported, unsafe, reference, forbidden-field, serialization, diagnostic sanitization, snapshot isolation, diagnostics isolation, bounded history, runtime limit, shutdown cleanup, global namespace, and no-execution behavior.

Self-checks are pre-start only and destructive. They are certification checks, not lifecycle tooling.

## Hardened Proof Matrix

The self-check suite proves every schema category rejects malformed, duplicate, unsupported, unsafe, and execution-shaped payloads. It separately proves startup, shutdown, initialization, restart, recovery, retry, restore, disable, pause, resume, unload, reload, lifecycle mutation, live EventBus emission, gameplay signal, Runtime Graph call, Security call, Save call, Presentation call, service lookup, Framework reference, live runtime object, live lifecycle state, live service handle, live error object, secret stack trace, enforcement, remediation, moderation, punishment, migration execution, adapter loading, runtime patch, remote, client, DataStore, HTTP, messaging, analytics, telemetry, Chapter, story, dialogue, and cutscene fields reject.

Self-checks also prove category limits, reference limits, audit finding limits, global namespace rejection across all categories, snapshot isolation, diagnostics isolation, bounded validation failures, bounded snapshots, shutdown cleanup, and refusal to run after startup.
