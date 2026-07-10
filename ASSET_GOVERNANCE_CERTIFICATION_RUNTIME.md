# Asset Governance Certification Runtime

Phase 61 creates, and Phase 62 hardens, the Asset Governance Certification Runtime under `src/ServerScriptService/AssetGovernanceCertification/Core`.

The runtime certifies governance metadata eligibility only. It verifies whether the certified asset governance chain is structurally ready for certification, but it does not authorize execution, execute assets, mutate upstream runtimes, repair data, orchestrate systems, schedule work, persist data, create remotes, grant client authority, or add Chapter content.

Provider name:

- `assetGovernanceCertificationRuntime`

Snapshot kind:

- `assetGovernanceCertificationRuntimeSnapshot`

Owned schemas:

- `GovernanceCertification`
- `GovernanceCertificationRequirement`
- `GovernanceCertificationResult`
- `GovernanceCertificationAudit`

Diagnostics posture key:

- `assetGovernanceCertificationPosture`

The certification model covers the chain from `AssetManifest` through `AssetGovernanceIntegration`. Future execution runtimes are intentionally excluded.

Responsibilities:

- own certification, requirement, result, and audit metadata
- validate schemas before state mutation
- expose health-only diagnostics
- expose isolated snapshots
- preserve deterministic self-check evidence
- document certification eligibility rules

Dependencies:

- Core Runtime
- Governance
- the certified asset governance chain through `AssetGovernanceIntegrationCoordinator`

The runtime owns no client presentation, no remotes, no DataStore writes, no HTTP or messaging calls, no Workspace or storage mutation, and no asset execution permission. Its reserved signal constants are names only in this phase; the coordinator does not dispatch events.
