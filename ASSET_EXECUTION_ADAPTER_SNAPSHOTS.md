# Asset Execution Adapter Snapshots

Snapshots are isolated deep-copy records with kind `assetExecutionAdapterRuntimeSnapshot`.

Snapshots expose deterministic metadata only: counts, limits, runtime identity, coordinator identity, provider posture, documentation posture, Bootstrap posture, Governance snapshot providers, lowerCamelCase posture keys, copied schemas, and validation failure copies.

Snapshot capture records bounded snapshot history in state. Mutating a returned snapshot cannot mutate runtime state or later snapshots.

Snapshots do not expose executable adapter references, Roblox Instances, callbacks, listeners, runtime handles, registries, services, managers, loaders, dispatchers, schedulers, orchestrators, asset operations, gameplay state, Presentation state, Save state, or Chapter state.

