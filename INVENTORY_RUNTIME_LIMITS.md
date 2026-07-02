# Inventory Runtime Limits

Inventory Runtime is bounded by design.

- Profile records are capped.
- Item records are capped.
- Slots per profile are capped.
- Capacity values are capped.
- Tags are capped.
- Validation failure history is capped.
- Snapshot history is capped.
- Payload depth, node count, and string length are capped.

These limits prevent schema growth from becoming memory growth. Future production tuning may adjust limits, but no system may remove the boundaries entirely.
