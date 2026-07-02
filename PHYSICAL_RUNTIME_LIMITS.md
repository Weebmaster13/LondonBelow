# Physical Runtime Limits

Phase 21 uses explicit limits to protect long-running servers.

## Limits

- Registered objects: `500`
- Reservations: `260`
- Ownership records: `500`
- Transform records: `500`
- Validation failures: `180`
- Snapshot history: `80`
- Payload depth: `8`
- Payload nodes: `260`
- Payload string length: `512`
- Tags per object: `24`

Old records are trimmed when bounded histories exceed their limits.

## Cleanup Guarantees

When an object is removed or trimmed from the bounded object registry, related ownership records, reservations, lifecycle state, state schema, and transform schema are removed with it.

Shutdown clears every runtime table and counter.
