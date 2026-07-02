# Objective Runtime Limits

Objective Runtime is bounded by design.

- Objectives are capped.
- Tasks, requirements, dependencies, and progress records are capped.
- Tags are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, and string length are capped.

Source-of-truth schema categories reject once full instead of silently evicting objective state.
