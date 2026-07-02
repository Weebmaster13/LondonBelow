# Analytics Runtime Limits

Analytics Boundary is bounded by design.

- Event schemas are capped.
- Metric definitions are capped.
- Aggregation schemas are capped.
- Consent schemas are capped.
- Retention policies are capped.
- Report schemas are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, tag count, and string length are capped.

All ids share one global analytics schema namespace. Hitting a limit is a safe rejection, never collection, sending, tracking, reporting, or eviction of source-of-truth schemas.

## Category Limits

- Events: `MaxEvents`
- Metrics: `MaxMetrics`
- Aggregations: `MaxAggregations`
- Consents: `MaxConsents`
- Retentions: `MaxRetentions`
- Reports: `MaxReports`
- Validation failures: `MaxValidationFailures`
- Snapshot history: `MaxSnapshotHistory`

Every category is validated through diagnostics. Limit failures are observable and safe; they do not trigger telemetry, reporting, profiling, persistence, remotes, Workspace mutation, or gameplay execution.
