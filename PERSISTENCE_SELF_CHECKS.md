# Persistence Self-Checks

Persistence self-checks are destructive and should run before runtime start.

They prove malformed schemas reject, duplicate request/package/policy ids reject, valid boundary records register, unsafe payloads reject, forbidden execution fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no DataStore reads/writes, live persistence, profile loading, cloud saves, migration execution, save mutation, remotes, client save authority, Workspace mutation, or Chapter content exists.
