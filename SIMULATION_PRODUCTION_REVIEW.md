# Simulation Production Review

The Simulation Validation Framework is production-hardened as dormant infrastructure.

## Production Rules

- Default mode is `Disabled`.
- Valid modes are only `Disabled`, `SelfCheck`, and `Manual`.
- There are no client remotes.
- There is no Workspace mutation.
- There are no real scares, monsters, Chapter 1 logic, final UI, or final art.
- Engine systems do not depend on Simulation.

## Hardening Summary

- Scenario runs receive deterministic run IDs.
- Reports include duration and cleanup result.
- Runner failures create failed reports instead of crashing validation flow.
- Cleanup runs after every scenario.
- Report and trace memory are bounded.
- Invalid observations use the normal ObservationService rejection path.
- Failed execution bridge requests are checked for cooldown pollution.
- Stale zone cleanup is explicitly tested.
- Decision traces must contain real entries for non-silent scenarios.
- Diagnostics expose run counts, failure counts, warning counts, last run, durations, cleanup results, trace counts, and memory counts.

## How This Protects London Engine

Before Chapter 1 exists, Simulation proves that the engine can reject bad facts, route Director decisions, explain approvals, avoid execution on failure, keep memory bounded, expose diagnostics, and clean up synthetic state.

## Future Guardrails

Future phases should add scenarios for Audio Director, Lighting Director, Monster Director, Save/Checkpoint, and multiplayer stress. Each new scenario must include explicit fail criteria, not only a successful function call.
