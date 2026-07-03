# Condition Dependency Runtime

Condition dependencies are metadata about schema relationships. Supported dependency kinds include Requires, Blocks, ConflictsWith, SoftOrder, and FutureDependency.

Dependencies do not block runtime behavior, enforce ordering, evaluate prerequisites, or trigger gameplay. They are inert records for future tooling and governance-aware runtimes.

The runtime rejects self dependencies, invalid condition references, duplicate ids, and direct two-condition dependency cycles before mutation.

## Production Hardening

Dependencies reject unsupported schema types, invalid source/target references, self dependencies, direct cycles, blocking execution markers, unsafe payloads, runtime object markers, callbacks, services, remotes, and Workspace markers. Dependencies are metadata only, not blockers.
