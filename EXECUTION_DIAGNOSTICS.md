# Execution Diagnostics

`ExecutionDiagnostics` exposes read-only runtime health for Phase 20.

## Exposed Fields

- initialized
- started
- execution queue count
- pending count
- approved count
- rejected count
- cancelled count
- expired count
- dry-run count
- validation failures
- runtime limits
- health
- serialization posture
- snapshot count
- last self-check result
- queue state
- audit count
- dependency count
- approval count
- snapshot isolation proof

## Rules

Diagnostics must never expose unsafe runtime values. Returned diagnostics are copies and cannot mutate runtime state.
