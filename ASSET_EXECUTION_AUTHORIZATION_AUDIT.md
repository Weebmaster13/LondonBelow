# Asset Execution Authorization Audit

`ExecutionAuthorizationAudit` records copied review metadata for an authorization.

Fields:

- `auditId`
- `authorizationId`
- `evaluationIds`
- `boundaryIds`
- `auditKind`
- `auditStatus`
- `reviewer`
- `evidence`
- `tags`
- `metadata`

Audits validate that referenced evaluations and boundaries exist and belong to the same authorization. Audit status never approves, rejects, routes, schedules, dispatches, orchestrates, executes, or mutates live work.
