# Runtime Graph Self-Checks

`RuntimeGraphSelfChecks.lua` certifies the boundary before startup.

Self-checks prove malformed, duplicate, unsupported, unsafe, missing-reference, direct-cycle, direct-contradiction, oversized-plan, oversized-group, serialization, diagnostic sanitization, snapshot isolation, diagnostics isolation, bounded history, shutdown cleanup, global namespace, and no-execution behavior.

Self-checks are pre-start only and destructive. They are certification checks, not runtime orchestration tools.

The production-hardening suite also proves category-specific unsafe payloads, module references, service references, execution adapters, runtime objects, execution permissions, service lookup, dependency injection, migration execution, adapter loading, startup/shutdown execution, Framework mutation, live mutation, execution groups, enforcement payloads, and every runtime category limit.
