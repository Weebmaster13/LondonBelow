# Cognition Serialization

Serialization exists for future replay, debugging, save-safe export, diagnostics, and snapshot isolation.

## Guarantees

- Serialization validates before unsafe data enters cognition.
- Deep copies are returned for public inspection and snapshots.
- Public callers must not receive mutable internal runtime tables.
- Cyclic tables reject.
- Roblox Instances reject.
- Functions, threads, and userdata reject.
- Oversized payloads reject by depth, node count, and string length.

## What Serialization Is Not

Serialization is not a save system yet. It is not a replay system yet. It does not authorize execution and does not turn cognition into gameplay truth.

## Future Schema Work

When save or replay support is introduced, every exported cognition record should receive an explicit schema version, migration rule, retention rule, and compatibility test. Until then, serialization remains a safe isolated export boundary.