# Performance Runtime Limits

Performance Budget Runtime is bounded by design.

- Budget schemas are capped.
- Category schemas are capped.
- Threshold schemas are capped.
- Report schemas are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, tag count, and string length are capped.

All ids share one global performance schema namespace. Hitting a limit is a safe rejection, never live profiling, optimization execution, automatic throttling, analytics collection, telemetry sending, client monitoring, or source-of-truth eviction.

## Certified Limits

- `MaxBudgets` bounds future CPU, memory, network, render, and category budget schemas.
- `MaxCategories` bounds runtime budget category schemas.
- `MaxThresholds` bounds warning threshold schemas.
- `MaxReports` bounds budget report schemas.
- `MaxValidationFailures` bounds sanitized rejection history.
- `MaxSnapshotHistory` bounds snapshot history.
- `MaxPayloadDepth`, `MaxPayloadNodes`, `MaxPayloadStringLength`, and `MaxTags` bound schema shape.

Every limit rejects before registration mutates state. Limits are not automatic throttles and do not start profilers, optimization passes, telemetry, client monitoring, or runtime mutation.
