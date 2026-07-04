# Approval Audit Runtime

`ApprovalAudit` records audit metadata attached to an approval.

Fields:

- `auditId`
- `approvalId`
- `auditKind`
- `reviewer`
- `status`
- `findings`
- `tags`
- `metadata`

Audits are schema records only. They do not execute remediation or approve runtime behavior.
