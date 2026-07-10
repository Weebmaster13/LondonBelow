# Asset Governance Integration Diagnostics

Diagnostics are health-only copied metadata. They expose lifecycle state, validation health, counts, limit usage, runtime limits, posture strings, bounded validation failures, and the last self-check result.

The diagnostics provider is `assetGovernanceIntegrationRuntime`.

Posture keys are lowerCamelCase:

- `assetGovernanceIntegrationPosture`
- `readOnlyIntegrationPosture`
- `noLoadingPosture`
- `noExecutionPosture`
- `noMutationPosture`
- `providerReadinessPosture`
- `chainOrderPosture`

Diagnostics do not expose services, runtime handles, asset handles, loaded assets, remotes, Workspace references, callbacks, listeners, execution adapters, client state, or mutable internal tables.
