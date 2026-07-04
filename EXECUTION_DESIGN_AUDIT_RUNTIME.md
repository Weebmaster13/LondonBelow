# Design Audit Runtime

`ExecutionDesignAudit` records audit metadata attached to a design contract.

Fields:

- `auditId`
- `contractId`
- `auditKind`
- `reviewer`
- `status`
- `findings`
- `tags`
- `metadata`

Audits are schema records only. They do not execute remediation or approve runtime behavior.
