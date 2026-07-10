# Asset Governance Integration Diagnostics

Diagnostics are health-only copied metadata. They expose lifecycle state, validation health, counts, limit usage, runtime limits, posture values, bounded validation failures, and the last self-check result.

The diagnostics provider is:

- `assetGovernanceIntegrationRuntime`

Diagnostics posture keys:

- `assetGovernanceIntegrationPosture`
- `readOnlyIntegrationPosture`
- `noLoadingPosture`
- `noExecutionPosture`
- `noMutationPosture`
- `providerReadinessPosture`
- `chainOrderPosture`
- `diagnosticsIsolationProof`
- `snapshotIsolationProof`

Diagnostics include no services, Instances, functions, threads, userdata, runtime handles, asset handles, loaded assets, remotes, Workspace references, callbacks, listeners, execution adapters, client state, or mutable internal tables.

Diagnostics are copied through `State.inspect()` and serialization-safe posture data. They are not authority and cannot repair, mutate, execute, load, or grant permission.
