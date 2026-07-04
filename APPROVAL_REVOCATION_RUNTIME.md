# Approval Revocation Runtime

`ApprovalRevocation` records revocation metadata for an approval.

Fields:

- `revocationId`
- `approvalId`
- `revocationKind`
- `revokedBy`
- `reason`
- `active`
- `tags`
- `metadata`

Revocations are ledger records only. They do not unload, disable, mutate, or remove assets.
