# Asset Execution Governance Validation

Validation rejects nil and non-table schemas, unsupported fields, invalid ids, unsupported enum values, unsafe payloads, duplicate ids, missing references, and bounded limit violations.

Validation runs before mutation. Failed validation records a bounded diagnostic failure through the coordinator and does not create or change governance, requirement, assessment, finding, or audit state.

Accepted schema fields match `AssetExecutionGovernanceTypes.SchemaFields`. Runtime metadata must use `runtimeName = "AssetExecutionGovernance"`, `providerName = "assetExecutionGovernanceRuntime"`, and `snapshotProviderName = "assetExecutionGovernanceRuntime"`.
