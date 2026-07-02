# Execution Audit

`ExecutionAuditRuntime` records why execution requests were accepted, rejected, or dry-run planned.

## Audit Fields

- execution id
- requester
- source system
- status
- reason
- priority
- dependencies
- approvals
- timestamp
- dry-run record

## Rules

- Audit records are bounded.
- Audit payloads are deep-copied.
- Unsafe values are rejected or sanitized before diagnostics.
- Audit history does not execute gameplay or authorize clients.
