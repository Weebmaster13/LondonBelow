# Asset Execution Audit

`ExecutionAudit` records copied review metadata for execution runtime records.

Fields:

- `auditId`
- `runtimeId`
- `requestIds`
- `boundaryIds`
- `auditKind`
- `auditStatus`
- `reviewer`
- `evidence`
- `tags`
- `metadata`

Audits validate that referenced requests and boundaries exist and belong to the same execution runtime. Audit status never approves, rejects, routes, schedules, dispatches, orchestrates, executes, or mutates live work.
