# Persistence Runtime Limits

Persistence Boundary is bounded by design.

- Requests are capped.
- Save/load packages are capped.
- Migrations, policies, and failure records are capped.
- Tags are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, and string length are capped.

Source-of-truth schema categories reject once full instead of silently evicting persistence boundary records.
