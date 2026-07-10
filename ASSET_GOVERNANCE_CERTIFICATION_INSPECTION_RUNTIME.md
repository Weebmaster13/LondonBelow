# Asset Governance Certification Inspection Runtime

Phase 68 production-hardens the Asset Governance Certification Inspection Runtime created in Phase 67.

Provider and coordinator names:

- runtime name: Asset Governance Certification Inspection Runtime
- coordinator: `AssetGovernanceCertificationInspectionCoordinator`
- diagnostics provider: `assetGovernanceCertificationInspectionRuntime`
- snapshot kind: `assetGovernanceCertificationInspectionRuntimeSnapshot`

Owned schemas and exact fields:

`GovernanceInspection`

- `inspectionId`
- `inspectionKind`
- `inspectionStatus`
- `integrationId`
- `certificationId`
- `coverageId`
- `observationIds`
- `findingIds`
- `auditIds`
- `inspector`
- `inspectionVersion`
- `tags`
- `metadata`

`GovernanceInspectionObservation`

- `observationId`
- `inspectionId`
- `runtimeName`
- `providerName`
- `snapshotProviderName`
- `observationKind`
- `observationStatus`
- `health`
- `evidence`
- `tags`
- `metadata`

`GovernanceInspectionFinding`

- `findingId`
- `inspectionId`
- `observationId`
- `runtimeName`
- `providerName`
- `snapshotProviderName`
- `findingKind`
- `findingSeverity`
- `findingStatus`
- `summary`
- `evidence`
- `tags`
- `metadata`

`GovernanceInspectionAudit`

- `auditId`
- `inspectionId`
- `findingIds`
- `auditKind`
- `reviewer`
- `status`
- `findings`
- `tags`
- `metadata`

The runtime observes copied health metadata only. Findings are reports only. Audits are review evidence only. Nothing repairs, authorizes, mutates, schedules, orchestrates, persists, networks, or executes.
