# Governance Certification Result Runtime

`GovernanceCertificationResult` records describe certification review outcomes.

Fields:

- `resultId`
- `certificationId`
- `resultKind`
- `resultStatus`
- `message`
- `evidence`
- `tags`
- `metadata`

Results are certification evidence only and do not grant execution permission.

Accepted `resultKind` values:

- `EligibilityResult`
- `ProviderResult`
- `DependencyResult`
- `GovernanceResult`
- `DiagnosticsResult`
- `SnapshotResult`
- `BootstrapResult`
- `DocumentationResult`
- `IntegrationResult`
- `FutureResult`

Accepted `resultStatus` values:

- `Passed`
- `Failed`
- `Warning`
- `Blocked`
- `NeedsReview`
- `Deferred`

`certificationId` must reference an already registered `GovernanceCertification`. `message` must be non-empty. `evidence` is a bounded id array with `MaxResultEvidence = 40`. Result records are copied metadata, not callbacks, adapters, remotes, or execution grants.
