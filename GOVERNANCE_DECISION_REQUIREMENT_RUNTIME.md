# Governance Decision Requirement Runtime

`GovernanceDecisionRequirement` records the copied requirement metadata used by the decision runtime.

Exact fields:

- `requirementId`
- `decisionId`
- `requirementKind`
- `requirementStatus`
- `runtimeName`
- `providerName`
- `snapshotProviderName`
- `evidence`
- `tags`
- `metadata`

Accepted `requirementKind` values:

- `BootstrapConsistencyRequirement`
- `CopiedEvidenceRequirement`
- `DocumentationConsistencyRequirement`
- `FutureRequirement`
- `GovernanceConsistencyRequirement`
- `ProviderConsistencyRequirement`
- `RuntimeConsistencyRequirement`
- `SnapshotConsistencyRequirement`

Accepted `requirementStatus` values:

- `Deferred`
- `Required`
- `Satisfied`
- `Unsatisfied`
- `Warning`

Requirement records must reference an existing decision before storage. Runtime, provider, and snapshot provider values must describe the same certified runtime entry. Unsupported fields reject; the exact fields above are the complete accepted surface.

Requirement records are metadata only. They do not trigger execution, authorization, approval, rejection, repair, orchestration, scheduling, remotes, client authority, persistence, asset operations, gameplay, Presentation, Save, or Chapter content.

Phase 76 production-hardens integration-readiness metadata that may reference requirement compatibility for future governed systems. It remains exact copied metadata only and cannot route, dispatch, authorize, approve, reject, repair, execute, orchestrate, or schedule work.
