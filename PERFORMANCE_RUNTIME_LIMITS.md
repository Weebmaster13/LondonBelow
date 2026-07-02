# Performance Runtime Limits

Performance Budget Runtime is bounded by design.

- Budget schemas are capped.
- Category schemas are capped.
- Threshold schemas are capped.
- Report schemas are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, tag count, and string length are capped.

All ids share one global performance schema namespace. Hitting a limit is a safe rejection, never live profiling, optimization execution, automatic throttling, analytics collection, telemetry sending, client monitoring, or source-of-truth eviction.
