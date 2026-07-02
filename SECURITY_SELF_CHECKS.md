# Security Self-Checks

Security self-checks are destructive and must run before runtime start.

They prove malformed, duplicate, unsafe, and valid paths for trust policies, authority rules, exploit signals, client rejection categories, remote safety schemas, rate-limit policies, and audit records.

They also prove duplicate ids reject globally across every security category, unsupported schema types reject, unsafe metadata/context/tags reject, forbidden execution and enforcement fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no live anti-cheat, exploit detection execution, ban/kick enforcement, moderation, punishment, client monitoring, remote creation, `RemoteEvent`/`RemoteFunction` handling, DataStore reads/writes, analytics collection, telemetry sending, Workspace mutation, gameplay execution, or Chapter content exists.

Self-checks use synthetic schemas only. They must not become security enforcement, live client inspection, telemetry, moderation, or punishment.
