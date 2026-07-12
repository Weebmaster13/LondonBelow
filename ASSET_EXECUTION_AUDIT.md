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

Phase 92 self-checks explicitly prove same-runtime audit integrity by rejecting audits that reference request or boundary metadata owned by another runtime. Rejection occurs before mutation and does not change audit counts.
