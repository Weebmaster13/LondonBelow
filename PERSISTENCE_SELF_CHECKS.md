# Persistence Self-Checks

Persistence self-checks are destructive and should run before runtime start.

They prove malformed schemas reject, unsupported schema types reject, duplicate request/package/migration/policy/failure ids reject, valid boundary records register, malformed save/load package schema pairs reject, malformed write/retry policy schema pairs reject, unsafe request/package/failure payloads reject, forbidden execution fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no DataStore reads/writes, live persistence, profile loading, cloud saves, migration execution, save mutation, remotes, client save authority, Workspace mutation, or Chapter content exists.

Self-checks must remain destructive because they intentionally exercise duplicate and shutdown behavior. They should be run before `PersistenceCoordinator.start()` and never as live gameplay logic.
