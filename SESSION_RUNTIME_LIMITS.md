# Session Runtime Limits

Session Runtime is bounded by design.

- Sessions are capped.
- Player session records are capped.
- Party, readiness, lifecycle, and join/leave records are capped.
- Tags are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, and string length are capped.

Source-of-truth schema categories reject once full instead of silently evicting session state.
