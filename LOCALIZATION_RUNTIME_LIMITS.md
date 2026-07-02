# Localization Runtime Limits

Localization Runtime is bounded by design.

- Language schemas are capped.
- Text key schemas are capped.
- Package schemas are capped.
- Fallback schemas are capped.
- Subtitle schemas are capped.
- Caption schemas are capped.
- Text safety schemas are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, string length, and tag count are capped.

All ids share one global localization namespace. Hitting a limit is a safe rejection, never translation, rendering, content eviction, automatic fallback execution, external service usage, or source-of-truth mutation.
