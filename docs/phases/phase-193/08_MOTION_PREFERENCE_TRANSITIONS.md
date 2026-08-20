# Phase 193 - Motion Preference Transitions
## Ownership
Changing from Full to Reduce or Remove cancels active transitions before the stricter preference governs new work. Counters record the exact number cancelled. Returning to Full affects future requests only.
## Non-Ownership
Motion preference remains local presentation state and is not persisted.
## Certification Boundary
Studio must verify tightening cancellation, no-op replay, and subsequent timing behavior.
