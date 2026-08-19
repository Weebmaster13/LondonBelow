# Phase 186 - RECONCILIATION AND IDEMPOTENCY.md

Same contract identity and revision returns an idempotent success without rebuilding. A changed revision stages a replacement and performs a deterministic root swap. Registry metadata tracks the active revision and node count.

## Ownership

Phase 186 owns active contract identity, revision idempotency, replacement reconciliation, and unmount.

## Non-Ownership

Phase 186 does not own semantic UI state migration, input focus restoration, or gameplay state preservation.

## Certification Boundary

Phase 186 is Production Candidate only. Phase 108 remains the latest Production Certified milestone until authoritative Roblox Studio Runtime Execution Framework evidence is imported and validated.
