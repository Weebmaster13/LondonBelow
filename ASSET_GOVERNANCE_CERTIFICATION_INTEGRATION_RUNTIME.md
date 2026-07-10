# Asset Governance Certification Integration Runtime

Phase 65 creates the Asset Governance Certification Integration Runtime under `src/ServerScriptService/AssetGovernanceCertificationIntegration/Core`.

This runtime coordinates copied certification metadata across the Asset Governance subsystem. It is deterministic, metadata-only, read-only, server-authoritative, and isolated.

Provider name:

- `assetGovernanceCertificationIntegrationRuntime`

Snapshot kind:

- `assetGovernanceCertificationIntegrationRuntimeSnapshot`

Owned schemas:

- `GovernanceCertificationIntegration`
- `GovernanceCertificationIntegrationChain`
- `GovernanceCertificationIntegrationReview`
- `GovernanceCertificationIntegrationAudit`

The runtime coordinates copied metadata for the certified chain from `AssetManifest` through `AssetGovernanceCertification`. It does not inspect live runtime state, repair records, mutate upstream runtimes, authorize execution, execute assets, orchestrate systems, schedule work, create remotes, grant client authority, persist data, or add Chapter content.

Responsibilities:

- own certification integration metadata
- own copied dependency, readiness, provider, Bootstrap, documentation, and compatibility metadata schemas
- validate schemas before state mutation
- expose health-only diagnostics
- expose isolated snapshots
- preserve deterministic self-check evidence
- document certification coordination boundaries

Dependencies:

- Core Runtime
- Governance
- the certified asset governance chain through `AssetGovernanceCertificationCoordinator`

Reserved signal constants are names only in this phase; the coordinator does not dispatch events.
