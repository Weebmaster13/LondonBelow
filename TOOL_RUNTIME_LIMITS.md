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
