# Persistence Runtime Limits

Persistence Boundary is bounded by design.

- Requests are capped.
- Save/load packages are capped.
- Migrations, policies, and failure records are capped.
- Tags are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, and string length are capped.

Source-of-truth schema categories reject once full instead of silently evicting persistence boundary records.

## Category Limits

- Requests: `MaxRequests`
- Save/load packages: `MaxPackages`
- Migration schemas: `MaxMigrations`
- Write and retry policies combined: `MaxPolicies`
- Failure records: `MaxFailures`
- Validation failures: `MaxValidationFailures`
- Snapshot history: `MaxSnapshotHistory`

Every category is validated through diagnostics. Hitting a limit is a safe rejection, never an eviction of source-of-truth records and never a trigger for live persistence.
