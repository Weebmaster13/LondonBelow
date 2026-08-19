# Phase 186 - ARCHITECTURE.md

The runtime is split into catalog, typed-value decoder, validator, transaction, registry, runtime, and controller. Rendering follows validate -> topological order -> detached staging -> atomic root mount -> old-root destruction.

## Ownership

Phase 186 owns the client-side renderer and its deterministic transaction boundary.

## Non-Ownership

Phase 186 does not own server orchestration, Director decisions, observation truth, or contract delivery.

## Certification Boundary

Phase 186 is Production Candidate only. Phase 108 remains the latest Production Certified milestone until authoritative Roblox Studio Runtime Execution Framework evidence is imported and validated.
