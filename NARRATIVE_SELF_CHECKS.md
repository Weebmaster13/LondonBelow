# Narrative Self-Checks

Narrative self-checks are deterministic certification scenarios for the Phase 19 runtime.

## What They Prove

- Malformed beats reject.
- Duplicate beats reject.
- Valid beats register.
- Unsafe beat payloads reject.
- Malformed story gates reject.
- Duplicate story gates reject.
- Valid story gates register.
- Unsafe story gate payloads reject.
- Reveal eligibility grants.
- Malformed reveals reject.
- Duplicate reveals reject.
- Unsafe reveal payloads reject.
- Emotional protections register.
- Duplicate emotional protections reject.
- Invalid emotional protections reject.
- Pressure suppression works without owning horror pacing.
- Serialization rejects cyclic tables, unsafe runtime values, and oversized payloads.
- Diagnostics are read-only returned copies.
- Snapshots are isolated deep copies.
- Runtime histories are bounded.
- Shutdown clears runtime state.

## Non-Ownership Proofs

Self-checks also record explicit non-ownership proofs: no final dialogue, no final story prose, no Chapter content, no cutscenes, no UI, no Workspace mutation, no Audio/Lighting execution, no Monster AI ownership, no horror pacing ownership, and no client-owned narrative truth.

## Safety Rule

Self-checks are destructive. They must run before the service starts, never while a live narrative session is active.
