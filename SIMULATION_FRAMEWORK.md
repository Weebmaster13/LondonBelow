# Simulation Framework

Phase 9 adds a dev-only Simulation and Validation Framework under `ServerScriptService/Core/Simulation`.

It is disabled by default:

```lua
SimulationConfig.Mode = "Disabled"
```

Supported modes:

- `Disabled`: default; registers diagnostics/snapshot providers but refuses scenario execution.
- `SelfCheck`: runs all scenarios at startup for explicit development validation.
- `Manual`: scenarios can be run through trusted server code.

## Rules

- No client remotes.
- No Workspace mutation.
- No real scares.
- No monsters.
- No Chapter 1 logic.
- No final UI or art.
- No live player truth mutation.
- Synthetic player profiles and synthetic zones only.
- Engine systems must never depend on Simulation.

## Scenarios

- Idle Silence
- Speedrunner Pressure
- Lantern Overuse
- Note Ignorer
- Party Split
- Execution Bridge Failure
- Invalid Observation
- Stale Zone Cleanup

## Reports

Every report includes scenario status, synthetic players/zones, injected and rejected observations, pressure timeline, candidate/rejected/approved decisions, failed bridge calls, cooldown changes, memory changes, diagnostics snapshots, decision traces, and architectural violations.

Reports also include deterministic run IDs, duration, cleanup result, warnings, and failures. A scenario cannot pass unless the validator finds required evidence for that scenario.

## Safe Enablement

Simulation must remain disabled by default. To run it manually in trusted server development code, call:

```lua
SimulationService.setMode("Manual")
SimulationService.runScenario("PartySplit")
```

`SelfCheck` may be used temporarily in local development by changing `SimulationConfig.Mode`, but that change must not be committed for production.

## Adding a Scenario

1. Add a fixture in `SimulationFixtures`.
2. Register it in `SimulationRegistry`.
3. Add the ID to `SimulationConfig.RequiredScenarioIds`.
4. Add explicit pass/fail evidence checks in `SimulationValidator`.
5. Document any new architecture boundary the scenario protects.

## Purpose

The lab proves London Engine systems can speak to each other before real gameplay exists. It exercises Observation validation, DirectorCoordinator request flow, Environment Director approvals, Governance registration, Player Runtime diagnostics, snapshots, and trace reporting without adding content.
