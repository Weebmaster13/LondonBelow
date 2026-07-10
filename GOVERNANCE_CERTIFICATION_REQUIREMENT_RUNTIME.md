# Governance Certification Requirement Runtime

`GovernanceCertificationRequirement` records describe a certification requirement.

Fields:

- `requirementId`
- `certificationId`
- `requirementKind`
- `required`
- `status`
- `summary`
- `tags`
- `metadata`

Requirements verify metadata readiness only.

Accepted `requirementKind` values:

- `RuntimePresenceRequirement`
- `ProviderConsistencyRequirement`
- `DependencyOrderingRequirement`
- `GovernanceContractRequirement`
- `DiagnosticsCompatibilityRequirement`
- `SnapshotCompatibilityRequirement`
- `BootstrapOrderingRequirement`
- `DocumentationCompletenessRequirement`
- `IntegrationReadinessRequirement`
- `FutureRequirement`

Accepted `status` values:

- `Passed`
- `Failed`
- `Warning`
- `Blocked`
- `NeedsReview`
- `Deferred`

`certificationId` must reference an already registered `GovernanceCertification`. `required` must be a boolean, and `summary` must be a non-empty string. Requirements do not inspect or mutate upstream runtimes directly.
