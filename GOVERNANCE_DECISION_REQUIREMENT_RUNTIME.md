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

Phase 77 execution-readiness metadata may reference requirement compatibility as future governed execution prerequisite evidence. Requirement records remain copied metadata only and cannot authorize or execute work.

Phase 78 hardening does not change requirement authority. Requirement records cannot grant execution permission, issue tokens, route work, dispatch work, schedule queues, or stand in for a future authorization runtime.
