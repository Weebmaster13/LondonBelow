# Security Self-Checks

Security self-checks are destructive and must run before runtime start.

They prove malformed, duplicate, unsafe, and valid paths for trust policies, authority rules, exploit signals, client rejection categories, remote safety schemas, rate-limit policies, and audit records.

They also prove duplicate ids reject globally across every security category, unsupported schema types reject, unsafe metadata/context/tags reject, forbidden execution and enforcement fields reject, serialization rejects cycles, Roblox Instances, unsafe runtime values, oversized payloads, and deep payloads, snapshots are isolated, diagnostics are read-only, histories are bounded, shutdown clears state, and no live anti-cheat, exploit detection execution, ban/kick enforcement, moderation, punishment, client monitoring, remote creation, `RemoteEvent`/`RemoteFunction` handling, DataStore reads/writes, analytics collection, telemetry sending, Workspace mutation, gameplay execution, or Chapter content exists.

Self-checks use synthetic schemas only. They must not become security enforcement, live client inspection, telemetry, moderation, or punishment.

## Hardened Proof List

The self-check suite proves malformed, duplicate, unsupported-type, unsafe, and valid registration paths for all seven schema categories. It proves global id rejection across the category chain, unsafe metadata/context/tags rejection, nested forbidden field rejection, forbidden table key rejection, forbidden string value rejection, individual forbidden execution/enforcement field rejection, serialization safety, diagnostic sanitization, isolated snapshots, read-only diagnostics, bounded histories, bounded snapshots, runtime category limit rejection, shutdown cleanup, and refusal to run destructive checks after runtime start.

The no-execution checks prove no live anti-cheat, exploit detection execution, ban/kick enforcement, moderation, punishment, client monitoring, remote creation, `RemoteEvent`/`RemoteFunction` handling, DataStore reads/writes, analytics collection, telemetry sending, Workspace mutation, gameplay execution, or Chapter content exists.
