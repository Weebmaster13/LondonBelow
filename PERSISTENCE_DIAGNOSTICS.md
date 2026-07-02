# Persistence Diagnostics

Persistence diagnostics expose lifecycle state, request count, package count, migration count, policy count, failure count, validation failures, snapshot count, runtime limits, serialization posture, no-execution posture, last self-check result, and health state.

Diagnostics are read-only copies and safe for Framework health checks.

## Hardened Signals

Diagnostics also expose:

- per-category limit usage for requests, packages, migrations, policies, failures, validation failures, and snapshots
- snapshot isolation proof
- serialization posture proving Instance, cycle, unsafe runtime value, and oversized payload rejection
- no-execution posture proving no DataStore reads/writes, live persistence, profile loading, cloud saves, migration execution, save mutation, remotes, client save authority, Workspace mutation, or Chapter content

Validation fails if any bounded category exceeds its runtime limit.
