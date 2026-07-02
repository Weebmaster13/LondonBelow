# Execution Approval Runtime

`ExecutionApprovalRuntime` verifies approval evidence attached to an execution request.

## Approval Shape

Approvals are table records with:

- `approvalId`
- `status`
- optional metadata that remains serializable and schema-only

## Rules

- At least one approved approval is required.
- Duplicate approval ids reject.
- Rejected, cancelled, expired, unknown, or missing approval statuses reject.
- Approval storage is bounded by execution request history.

## Boundary

Approvals prove that another server-authoritative system permitted a dry-run plan. They do not execute the plan and do not grant client authority.
