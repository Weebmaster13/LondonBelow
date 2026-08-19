# Phase 189 - Generation Fencing

Every successful reconciliation attempt advances a monotonic local generation after old connections disconnect. Each event closure captures its generation. Activation rejects when the captured generation differs from the current generation, protecting against queued stale events during rapid root replacement. Unmount also advances the fence.

## Ownership

Phase 189 owns local stale-generation rejection and diagnostics.

## Non-Ownership

Generation numbers are not server revisions, security tokens, or persistence identities.

## Certification Boundary

Queued stale activation must be demonstrated in Studio stress evidence.
