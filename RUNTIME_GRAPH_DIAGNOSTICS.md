# Runtime Graph Diagnostics

Diagnostics are health-only, not live orchestration.

Diagnostics expose lifecycle state, health, validation status, category counts, validation failure count, snapshot count, per-category limit usage, runtime limits, serialization posture, snapshot isolation proof, diagnostics isolation proof, graph integrity posture, cycle detection posture, capability/requirement/ordering integrity posture, startup/shutdown plan posture, no-execution posture, recent sanitized validation failures, and the last self-check result.

Diagnostics do not expose live runtime objects, service handles, Framework internals, module references, require handles, remotes, callbacks, Workspace references, or execution adapters.

Diagnostics now expose compatibility integrity posture and group integrity posture in addition to graph, cycle, capability, requirement, ordering, startup plan, and shutdown plan posture. The no-execution posture explicitly includes no Framework mutation, no dependency injection, and no service resolution.
