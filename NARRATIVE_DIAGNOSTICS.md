# Narrative Diagnostics

`NarrativeCoordinator.inspect` exposes read-only diagnostics for the Narrative Runtime foundation.

## Exposes

- Lifecycle state.
- Beat count.
- Story gate count.
- Reveal eligibility count.
- Emotional protection count.
- Validation failures.
- Runtime limits.
- Last self-check result.
- Health state.

Diagnostics are copied and must never become controls for story execution, UI, cutscenes, Workspace mutation, Audio, Lighting, Monster AI, or horror pacing.