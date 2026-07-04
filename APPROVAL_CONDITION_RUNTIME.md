# Approval Condition Runtime

`ApprovalCondition` records a condition attached to an approval.

Fields:

- `conditionId`
- `approvalId`
- `conditionKind`
- `required`
- `satisfied`
- `summary`
- `tags`
- `metadata`

Conditions are evidence metadata only. They do not execute checks, mutate approvals, or operate assets.
