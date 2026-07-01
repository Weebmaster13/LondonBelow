# Cognitive Pipeline

The cognitive pipeline is:

Trusted Observation -> Normalization -> Evidence -> Evidence Validation -> Hypothesis Generation -> Hypothesis Competition -> Thought Promotion -> Thought Competition -> Belief Update -> Goal Hook -> Future Intention Hook -> Diagnostics -> Snapshot

## Implementation Boundary

Phase 16 implements the substrate through belief update and exposes future hooks conceptually. It does not create goals, intentions, gameplay, or execution.

## Stage Responsibilities

- Observation Intake normalizes and validates.
- Evidence Runtime preserves context without claiming truth.
- Hypothesis Runtime keeps multiple explanations alive.
- Thought Runtime promotes strong hypotheses into reasoning candidates.
- Belief Runtime creates slow-changing conclusions.
- Diagnostics and Snapshots expose state for debugging, replay, and future save systems.

## Invariants

Unknown remains unknown until evidence justifies change. Confidence changes gradually. Guessing is forbidden.
