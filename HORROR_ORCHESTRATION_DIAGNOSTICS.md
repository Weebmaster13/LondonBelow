# Horror Orchestration Diagnostics

Horror Orchestration exposes diagnostics through `HorrorOrchestrator.inspect` and snapshots through `horrorOrchestration`.

## Exposed Data

- Pressure budget.
- Pending requests.
- Recent decisions.
- Suppressed decisions.
- Delayed decision counts.
- Release decision counts.
- Scare eligibility results inside bundle metadata.
- Chase preparation recommendations.
- Sensory and emotional load.
- Coordination bundles.
- Validation failures.
- Self-check results.
- Health.

## Self-Checks

Self-checks prove pressure stays bounded, silence can be selected, release can follow high pressure, safe rooms suppress scares, malformed requests reject, duplicate requests reject, expired requests reject, no Workspace mutation occurs, no client authority exists, no Monster AI executes, and shutdown clears queue/state.

## Debug Boundary

Diagnostics are observational. They must not become controls for final scares, lighting, sounds, movement, or client presentation.
