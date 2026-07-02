# Tool Diagnostics

Developer Tooling diagnostics expose:

- initialized
- started
- lifecycle state
- tool count
- inspection count
- command schema count
- report count
- permission count
- audit count
- validation failure count
- snapshot count
- runtime limits
- serialization posture
- snapshot isolation proof
- no-execution posture
- last self-check result
- health state

Diagnostics are read-only copies and safe for Framework health checks.

## Hardened Signals

Diagnostics also expose:

- per-category limit usage for tools, inspections, commands, reports, permissions, audits, validation failures, and snapshots
- lifecycle state for initialized, started, and stopped runtime modes
- snapshot isolation proof
- serialization posture proving Instance, cycle, unsafe runtime value, and oversized payload rejection
- no-execution posture proving no command execution, live admin tools, remote console, player-facing UI, moderation, analytics collection, exploit/backdoor tooling, DataStore reads/writes, Workspace mutation, remotes, client authority, or Chapter content

Validation fails if any bounded category exceeds its runtime limit.
