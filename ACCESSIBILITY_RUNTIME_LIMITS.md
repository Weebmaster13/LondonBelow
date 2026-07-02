# Accessibility Runtime Limits

Accessibility Runtime is bounded by design.

- Setting schemas are capped.
- Visual safety rules are capped.
- Audio safety rules are capped.
- Input assist schemas are capped.
- Motion comfort schemas are capped.
- Readability schemas are capped.
- Content warning schemas are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, tag count, and string length are capped.

All ids share one global accessibility schema namespace. Hitting a limit is a safe rejection, never UI, setting execution, input remapping, effect execution, or source-of-truth eviction.
