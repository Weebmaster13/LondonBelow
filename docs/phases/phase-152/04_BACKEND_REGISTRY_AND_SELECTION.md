# Backend Registry And Selection

Phase 152 adds `automation/runtime-execution/backends`.

The registry supports deterministic module registration, duplicate backend ID rejection, framework version checks, explicit availability, priority ordering, selection reason reporting, and no silent fallback.

Generated catalog:

`automation/runtime-execution/generated/backend-catalog.json`

Selected default backend:

`runtimeExecution.studioManual`

Reason:

It is the highest-priority available backend and provides a truthful source-bound manual path without fabricating automated Studio execution.
