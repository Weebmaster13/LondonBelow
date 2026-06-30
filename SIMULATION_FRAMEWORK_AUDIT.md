# Simulation Framework Audit

This audit reviewed the Phase 9 Simulation and Validation Framework as dev-only London Engine infrastructure.

## Reviewed

- `SimulationService`
- `SimulationTypes`
- `SimulationConfig`
- `SimulationRegistry`
- `SimulationScenarioRunner`
- `SimulationReportBuilder`
- `SimulationTraceRecorder`
- `SimulationValidator`
- `SimulatedPlayerProfiles`
- `SimulatedZoneModel`
- `SimulationFixtures`
- `SimulationDiagnostics`
- `SimulationSignals`
- Governance contract
- `SIMULATION_FRAMEWORK.md`
- `PHASE_9_SIMULATION_REVIEW.md`
- `README.md`
- `ROADMAP.md`
- `TASKS.md`
- `LONDON_ENGINE.md`

## Issues Found

- Reports had no deterministic run ID or explicit run duration.
- Scenario execution did not guarantee cleanup if the runner threw.
- Validation could pass with shallow evidence, especially if trace containers existed but were empty.
- Invalid observations used validator logic, but did not prove the normal `ObservationService.observe` rejection path.
- Diagnostics did not expose run count, fail count, warning count, last run, scenario durations, cleanup results, or memory counts.
- Disabled-by-default behavior was documented but not asserted by service validation.

## Fixes Made

- Added deterministic run IDs in the form `SIM-ScenarioId-0001`.
- Added report start time, completion time, and duration.
- Added failure-safe scenario execution with guaranteed cleanup.
- Added bounded cleanup result history.
- Strengthened per-scenario pass/fail evidence requirements.
- Added explicit trace-entry validation.
- Routed invalid observation scenarios through `ObservationService.observe`.
- Added service validation that requires default mode to remain `Disabled`.
- Improved diagnostics and snapshots with run counters, durations, trace counts, cleanup results, and memory counts.

## Remaining Risks

- Scenario timeout protection detects overruns after execution; it does not preempt a stuck Luau thread.
- Manual and SelfCheck mode intentionally touch development server modules, so they should only be enabled in trusted development sessions.
- Future isolated test containers could provide stronger no-side-effect guarantees.

## Safe Enablement

To enable manually in trusted server code:

```lua
SimulationService.setMode("Manual")
local report = SimulationService.runScenario("PartySplit")
```

To run all scenarios at startup in development only, set `SimulationConfig.Mode = "SelfCheck"` temporarily and never commit that change for production.

## Adding Scenarios

Add a fixture, register it in `SimulationRegistry`, add its ID to `SimulationConfig.RequiredScenarioIds`, and add explicit evidence checks in `SimulationValidator`.

## Fake Success Prevention

Reports must contain required evidence. A scenario cannot pass only because it produced a table. It must prove the expected observation, decision, trace, cleanup, cooldown, memory, or bridge behavior.

## Why Simulation Is Not Gameplay

Simulation exists to protect the engine before Chapter 1. It is disabled by default, has no remotes, owns no gameplay state, mutates no Workspace parts, and must never become a player-facing feature.
