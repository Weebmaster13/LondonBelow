# Analytics Diagnostics

Analytics diagnostics expose:

- initialized
- started
- lifecycle state
- event count
- metric count
- aggregation count
- consent count
- retention count
- report count
- validation failure count
- snapshot count
- runtime limits
- serialization posture
- snapshot isolation proof
- no-execution posture
- last self-check result
- health state

Diagnostics are read-only copies and safe for Framework health checks. They do not collect live analytics.

## Hardened Signals

Diagnostics also expose:

- per-category limit usage for events, metrics, aggregations, consents, retentions, reports, validation failures, and snapshots
- lifecycle state for initialized, started, and stopped runtime modes
- snapshot isolation proof
- serialization posture proving Instance, cycle, unsafe runtime value, and oversized payload rejection
- no-collection posture proving no analytics collection, telemetry sending, player tracking, external reporting, moderation, live metrics, HTTP calls, DataStore writes, MessagingService usage, remotes, client authority, Workspace mutation, gameplay execution, or Chapter content

Validation fails if any bounded category exceeds its runtime limit.
