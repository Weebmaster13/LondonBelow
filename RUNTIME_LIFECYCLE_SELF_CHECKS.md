# Runtime Lifecycle Self-Checks

`RuntimeLifecycleSelfChecks.lua` certifies Phase 38 before startup.

Self-checks prove malformed, duplicate, unsupported, unsafe, reference, forbidden-field, serialization, diagnostic sanitization, snapshot isolation, diagnostics isolation, bounded history, runtime limit, shutdown cleanup, global namespace, and no-execution behavior.

Self-checks are pre-start only and destructive. They are certification checks, not lifecycle tooling.
