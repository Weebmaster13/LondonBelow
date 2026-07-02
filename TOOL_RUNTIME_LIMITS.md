# Tool Runtime Limits

Developer Tooling Runtime is bounded by design.

- Tool definitions are capped.
- Inspection requests are capped.
- Command schemas are capped.
- Report packages are capped.
- Permission schemas are capped.
- Audit records are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, tag count, and string length are capped.

Source-of-truth categories reject once full instead of silently evicting developer tooling records.

## Category Limits

- Tool definitions: `MaxTools`
- Inspection requests: `MaxInspections`
- Command schemas: `MaxCommands`
- Report packages: `MaxReports`
- Permission schemas: `MaxPermissions`
- Audit records: `MaxAudits`
- Validation failures: `MaxValidationFailures`
- Snapshot history: `MaxSnapshotHistory`

All ids are also tracked in one global schema-id namespace, so a command cannot reuse a tool id and a report cannot reuse an audit id. Hitting any category limit is a safe rejection, never execution and never silent eviction of source-of-truth tooling schemas.
