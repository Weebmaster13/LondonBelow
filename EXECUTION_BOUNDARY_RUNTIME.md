# ExecutionBoundary Schema

`ExecutionBoundary` records prohibited execution surfaces as metadata only.

It requires an existing `ExecutionRuntime` parent and validates boundary kind, boundary status, summary, evidence, tags, and metadata.

It describes boundaries but does not execute or enforce live work.

Phase 92 keeps boundary arrays ordered, bounded, and duplicate-free when boundaries are referenced by runtime or audit records.

Phase 93 references boundary compatibility as copied metadata only. Boundaries still do not enforce live behavior.

Phase 94 hardens boundary-compatibility declarations as exact copied metadata only; boundary statuses still do not activate adapters or grant asset-operation permission.
