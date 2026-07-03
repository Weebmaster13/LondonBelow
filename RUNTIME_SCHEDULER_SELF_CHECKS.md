# Runtime Scheduler Self-Checks

`RuntimeSchedulerSelfChecks.lua` certifies Phase 39 before startup.

Self-checks prove malformed, duplicate, unsupported, unsafe, reference, forbidden-field, serialization, diagnostic sanitization, snapshot isolation, diagnostics isolation, bounded history, runtime limit, shutdown cleanup, global namespace, and no-execution behavior.

Self-checks are pre-start only and destructive. They are certification checks, not scheduling tooling.
