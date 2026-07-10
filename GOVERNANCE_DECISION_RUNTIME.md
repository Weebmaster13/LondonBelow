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
