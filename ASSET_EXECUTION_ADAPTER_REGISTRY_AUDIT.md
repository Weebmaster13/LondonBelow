# Asset Execution Adapter Registry Audit

Registry audit records are copied metadata only.

Audit fields:

- `auditId`
- `registryId`
- `registrationId`
- `boundaryIds`
- `compatibilityIds`
- `auditKind`
- `auditStatus`
- `reviewer`
- `evidence`
- `tags`
- `metadata`

Audit references must exist, must be ordered, must be duplicate-free, and boundary/compatibility references must belong to the same registration. Audits do not approve execution, activate adapters, route work, dispatch work, schedule work, orchestrate systems, load assets, play assets, mutate Workspace, create remotes, grant client authority, execute gameplay, execute Presentation, execute Save, or add Chapter content.
