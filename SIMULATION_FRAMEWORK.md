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

## Purpose

The lab proves London Engine systems can speak to each other before real gameplay exists. It exercises Observation validation, DirectorCoordinator request flow, Environment Director approvals, Governance registration, Player Runtime diagnostics, snapshots, and trace reporting without adding content.
