# Cognition Diagnostics

Living Cognition exposes diagnostics through `LivingCognitionCoordinator.inspect` and snapshots through the `livingCognition` snapshot provider.

## Exposed Data

- Current runtime state.
- Registered cognitive entity count.
- Observation, evidence, hypothesis, thought, and belief counts.
- Trace history and trace count.
- Confidence history.
- Thought lifecycle transition summaries.
- Validation failures and validation failure count.
- Bounded diagnostics history.
- Runtime limits.
- Self-check results.
- Serialization status.
- Snapshot isolation proof.
- Health state.

## Read-Only Boundary

Diagnostics are deep-copied and read-only from the caller's perspective. Mutating a diagnostics table must not mutate internal runtime state.

## Debug Boundary

Diagnostics must never become controls for gameplay, Monster AI, Workspace mutation, Lighting, Audio, or client presentation.