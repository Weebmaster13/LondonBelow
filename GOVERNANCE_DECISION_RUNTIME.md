# Governance Decision Runtime

`GovernanceDecision` records the deterministic decision metadata produced from copied governance inspection evidence.

Exact fields:

- `decisionId`
- `inspectionId`
- `decisionKind`
- `decisionStatus`
- `runtimeName`
- `providerName`
- `snapshotProviderName`
- `requirementIds`
- `evaluationIds`
- `auditIds`
- `evidence`
- `tags`
- `metadata`

Accepted `decisionKind` values:

- `BootstrapDecisionEvaluation`
- `CertificationDecisionEvaluation`
- `DocumentationDecisionEvaluation`
- `FutureDecisionEvaluation`
- `GovernanceDecisionEvaluation`
- `ProviderDecisionEvaluation`
- `RuntimeDecisionEvaluation`
- `SnapshotDecisionEvaluation`

Accepted `decisionStatus` values:

- `Blocked`
- `Deferred`
- `Evaluated`
- `Satisfied`
- `Unsatisfied`
- `Warning`

`runtimeName`, `providerName`, and `snapshotProviderName` must match the same certified runtime entry. Child references are bounded id arrays and must point to registered requirement, evaluation, and audit records when the decision is stored. Unsupported fields reject; the exact fields above are the complete accepted surface.

Decision records do not authorize, approve, reject, repair, orchestrate, schedule, execute, load assets, create remotes, mutate storage, mutate Workspace, or grant client authority.

Phase 76 production-hardens integration-readiness metadata that may reference decision compatibility for this schema. That compatibility is exact copied evidence only. It does not route, dispatch, authorize, approve, reject, repair, execute, orchestrate, or schedule decisions.

Phase 77 execution-readiness metadata may reference this schema as future governed execution prerequisite evidence. That evidence is copied metadata only; decision records and decision statuses do not grant execution permission.
