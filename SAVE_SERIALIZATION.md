# Save Serialization

`SaveSerialization` protects all public save, journal, memory, identity, replay, diagnostics, and snapshot exports.

## Rejects

- Roblox Instances.
- Cyclic tables.
- Functions, threads, and userdata.
- Oversized strings.
- Overly deep payloads.
- Payloads with too many nodes.

## Diagnostic Safety

Rejected payloads are copied through a sanitized diagnostics path, so unsafe runtime values are replaced with markers instead of being preserved raw.

## Isolation

Public snapshots and diagnostics are deep copies. Mutating returned tables must not mutate runtime state.