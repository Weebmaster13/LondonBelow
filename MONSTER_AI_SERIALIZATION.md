# Monster AI Serialization

Monster AI serialization protects diagnostics, snapshots, validation failures, and dry-run execution records.

## Validation Rejects

- Roblox Instances.
- Cyclic tables.
- Functions, threads, and userdata.
- Oversized strings.
- Overly deep payloads.
- Payloads with too many nodes.

## Diagnostic Sanitization

Rejected payloads are copied through `diagnosticCopy`, which replaces unsafe runtime values, cycles, future Roblox Instances, overly deep values, and oversized structures with safe markers. This prevents diagnostics from preserving unsafe objects while still leaving enough context to debug rejection causes.

## Isolation

Registry inspection, state inspection, diagnostics, snapshots, and execution records return copies. Callers must not be able to mutate internal Monster AI runtime state by editing returned tables.

## Future Save/Replay

This is not a save system yet. Future replay or persistence must add schema versions, migration rules, retention policies, and compatibility checks before any production storage is enabled.