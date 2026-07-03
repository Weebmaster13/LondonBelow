# Runtime Lifecycle Diagnostics

Diagnostics are health-only, not live lifecycle management.

Diagnostics expose lifecycle state, health, validation status, category counts, validation failure count, snapshot count, per-category limits, serialization posture, snapshot isolation proof, diagnostics isolation proof, lifecycle/transition/policy/guard/failure/recovery/checkpoint/audit/compatibility integrity posture, no-execution posture, recent sanitized validation failures, and the last self-check result.

Diagnostics do not contain live runtime state, live runtime objects, service handles, Framework internals, Runtime Graph internals, module references, require handles, remotes, Workspace references, callbacks, or execution adapters.
