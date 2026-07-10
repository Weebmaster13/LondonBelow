# Asset Governance Integration Validation

Validation occurs before mutation. Failed validation records a bounded sanitized failure through the coordinator and never registers schema data.

Accepted `chainKind` values:

- `CertifiedAssetGovernanceChain`
- `RuntimeProviderChain`
- `ReferenceReadinessChain`
- `FutureIntegrationChain`

Accepted `chainStatus` values:

- `Healthy`
- `Warning`
- `Blocked`
- `NeedsReview`
- `Deferred`

Accepted `nodeStatus` values:

- `Ready`
- `Missing`
- `Blocked`
- `NeedsReview`
- `Deferred`

Accepted `referenceKind` values:

- `ReadinessReference`
- `DesignContractReference`
- `AssetReference`
- `UsagePlanReference`
- `ChecklistReference`
- `ApprovalReference`
- `PermitReference`
- `GateReference`
- `RuntimeOrderReference`
- `FutureReference`

Accepted `referenceStatus` values:

- `Present`
- `Missing`
- `Passed`
- `Blocked`
- `NeedsReview`
- `Deferred`

Accepted `auditKind` values:

- `ChainAudit`
- `ProviderAudit`
- `ReferenceAudit`
- `ProductionAudit`
- `FutureAudit`

Accepted `audit` status values:

- `Passed`
- `Failed`
- `Warning`
- `Deferred`
- `Blocked`

Validation rejects nil schemas, non-table schemas, invalid ids, unsupported schema types, unsupported enum values, duplicate ids across this runtime, missing chain references, duplicate runtime names inside a chain, duplicate expected order values inside a chain, unknown runtime names, unknown provider names, invalid coordinator names, mismatched runtime/provider/coordinator/order combinations, unsafe tags, unsafe metadata, unsafe findings, functions, threads, userdata, Instance-shaped tables, callbacks, listeners, service handles, runtime handles, asset handles, loaded asset handles, module references, execution adapters, remotes, forbidden execution/client/storage/content markers, excessive depth, excessive node count, oversized strings, excessive tags, excessive audit findings, and excessive chain children.

Validation is intentionally metadata-only. It does not resolve upstream records and does not require upstream records to exist.
