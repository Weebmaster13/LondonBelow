# Implementation Readiness Gap Runtime

`ImplementationReadinessGap` records gap metadata attached to an implementation readiness record.

Fields:

- `gapId`
- `readinessId`
- `gapKind`
- `severity`
- `resolved`
- `summary`
- `tags`
- `metadata`
- `schemaType`

Gaps are ledger records only. They do not execute checks, mutate runtime behavior, or apply assets.
