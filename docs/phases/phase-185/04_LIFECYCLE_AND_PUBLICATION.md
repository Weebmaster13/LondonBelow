# Phase 185 - Lifecycle and Publication

Legal lifecycle: `Draft -> Validated -> Published -> Retired`, with `Draft/Validated -> Rejected`. Rejected and Retired are terminal. Publication produces immutable metadata; every public read returns an isolated copy.

## Ownership

The runtime owns registration, validation transition, publication, retirement, audit, reset, and shutdown.

## Non-Ownership

Publication is not rendering, replication, persistence, asset loading, or GUI mutation.

## Certification Boundary

Lifecycle self-checks establish deterministic authority behavior without asserting Studio execution.
