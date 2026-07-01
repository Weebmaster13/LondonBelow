# Cognition Diagnostics

Living Cognition exposes diagnostics through `LivingCognitionCoordinator.inspect` and snapshots through `livingCognition`.

## Exposed Data

- Current runtime state.
- Registered cognitive entities.
- Observation, evidence, hypothesis, thought, and belief counts.
- Trace history.
- Confidence evolution through records.
- Validation failures.
- Snapshot export.
- Self-check results.

## Debug Boundary

Diagnostics are read-only. They must never become controls for gameplay, Monster AI, Workspace mutation, Lighting, Audio, or client presentation.
