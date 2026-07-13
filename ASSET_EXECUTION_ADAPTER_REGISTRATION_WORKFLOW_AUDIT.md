# Asset Execution Adapter Registration Workflow Audit

Audit schema: `ExecutionAdapterRegistrationAudit`

Audit fields:

- `auditId`
- `workflowId`
- `stageIds`
- `transitionIds`
- `decisionIds`
- `auditKind`
- `auditStatus`
- `reviewer`
- `evidence`
- `tags`
- `metadata`

Audits summarize copied workflow metadata only. They do not approve execution, activate adapters, register adapters, route work, dispatch work, schedule work, orchestrate systems, load assets, mutate Workspace, create remotes, grant client authority, execute gameplay, execute Presentation, execute Save, or add Chapter content.