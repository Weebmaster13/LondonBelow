# Asset Execution Adapter Audit

`ExecutionAdapterAudit` records copied review metadata for one adapter.

Audit fields:

- `auditId`
- `adapterId`
- `capabilityIds`
- `compatibilityIds`
- `boundaryIds`
- `auditKind`
- `auditStatus`
- `reviewer`
- `evidence`
- `tags`
- `metadata`

Audit child references must exist, must be ordered, must be duplicate-free, and must belong to the same adapter. Audits do not approve execution, reject live work, route work, dispatch work, schedule work, orchestrate systems, load assets, play assets, mutate Workspace, create remotes, grant client authority, execute gameplay, execute Presentation, execute Save, or add Chapter content.

