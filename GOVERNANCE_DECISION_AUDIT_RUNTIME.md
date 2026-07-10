# Governance Decision Audit Runtime

`GovernanceDecisionAudit` records review metadata for decision evaluations.

Exact fields:

- `auditId`
- `decisionId`
- `evaluationIds`
- `auditKind`
- `auditStatus`
- `reviewer`
- `evidence`
- `tags`
- `metadata`

Accepted `auditKind` values:

- `CoverageAudit`
- `DecisionAudit`
- `EvaluationAudit`
- `FutureAudit`
- `ProductionAudit`
- `ProviderAudit`
- `RequirementAudit`

Accepted `auditStatus` values:

- `Blocked`
- `Deferred`
- `Failed`
- `Passed`
- `Warning`

Audit records must reference an existing decision and registered evaluation ids before storage. Validation rejects invalid reviewers, invalid ids, unsupported enum values, unsupported fields, duplicate ids, duplicate evaluation references, unsafe payloads, and missing references before mutation. The exact fields above are the complete accepted surface.

Audit records are review evidence only. They do not approve, reject, authorize, repair, orchestrate, schedule, execute, load assets, create remotes, mutate Workspace or storage, persist data, grant client authority, or create gameplay, Presentation, Save, or Chapter content.
