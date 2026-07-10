# Asset Governance Certification Integration Validation

Validation occurs before mutation. Failed validation records a bounded sanitized failure and never registers schema data.

Validation rejects nil schemas, non-table schemas, invalid ids, duplicate ids, unsupported enum values, invalid provider references, invalid dependency declarations, invalid runtime names, invalid coordinator names, invalid Bootstrap declarations, incomplete chain arrays, duplicate chain entries, unsafe metadata, unsafe tags, functions, threads, userdata, Instance-shaped tables, runtime handles, callbacks, listeners, execution adapters, module references, cycles, oversized payloads, deep payloads, authorization markers, repair markers, execution markers, orchestration markers, scheduling markers, live-runtime markers, and live-inspection markers.

Accepted `integrationKind` values:

- `CertificationCoordination`
- `DependencyCoordination`
- `ReadinessCoordination`
- `ProviderCoordination`
- `BootstrapCoordination`
- `DocumentationCoordination`
- `CompatibilityCoordination`
- `FutureCoordination`

Accepted `integrationStatus` values:

- `Draft`
- `Ready`
- `Coordinated`
- `Blocked`
- `NeedsReview`
- `Deferred`

Accepted `chainKind` values:

- `CertifiedGovernanceChain`
- `CertificationDependencyChain`
- `CertificationReadinessChain`
- `ProviderMetadataChain`
- `BootstrapMetadataChain`
- `DocumentationMetadataChain`
- `CompatibilityMetadataChain`
- `FutureMetadataChain`

Accepted `chainStatus` values:

- `Ready`
- `Coordinated`
- `Warning`
- `Blocked`
- `NeedsReview`
- `Deferred`

Accepted `reviewKind` values:

- `CertificationMetadataReview`
- `DependencyMetadataReview`
- `ReadinessMetadataReview`
- `ProviderMetadataReview`
- `BootstrapMetadataReview`
- `DocumentationMetadataReview`
- `CompatibilityMetadataReview`
- `FutureMetadataReview`

Accepted `reviewStatus` values:

- `Passed`
- `Warning`
- `Blocked`
- `NeedsReview`
- `Deferred`

Accepted `auditKind` values:

- `IntegrationAudit`
- `ChainAudit`
- `CertificationAudit`
- `ReadinessAudit`
- `ProviderAudit`
- `ProductionAudit`
- `FutureAudit`

Accepted `status` values for `GovernanceCertificationIntegrationAudit`:

- `Passed`
- `Failed`
- `Warning`
- `Deferred`
- `Blocked`

Validation confirms copied metadata shape only. It does not inspect live subsystem state, repair data, mutate upstream runtimes, or authorize execution.

Phase 66 hardens validation so `runtimeNames`, `providerNames`, and `readinessIds` must include the complete certified governance chain in exact order.
