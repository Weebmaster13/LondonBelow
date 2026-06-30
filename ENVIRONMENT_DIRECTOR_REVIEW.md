# Environment Director Review

This audit reviewed Phase 8 as the first real London Engine Director implementation. The review focused on request safety, reaction fairness, cooldown behavior, bounded memory, execution boundaries, diagnostics, Governance, and documentation.

## Reviewed

- `EnvironmentDirector.lua`
- `EnvironmentDirectorTypes.lua`
- `EnvironmentDirectorConfig.lua`
- `EnvironmentReactionRegistry.lua`
- `EnvironmentReactionSelector.lua`
- `EnvironmentPressureModel.lua`
- `EnvironmentMemory.lua`
- `EnvironmentState.lua`
- `EnvironmentZoneContext.lua`
- `EnvironmentExecutionBridge.lua`
- `EnvironmentDiagnostics.lua`
- `EnvironmentSignals.lua`
- Bootstrap and Framework integration
- DirectorCoordinator replacement of the foundation `Environment` Director
- Governance contract
- `ENVIRONMENT_DIRECTOR.md`
- `ENVIRONMENT_REACTIONS.md`
- `ENVIRONMENT_ZONES.md`
- `ENVIRONMENT_EXECUTION.md`

## Issues Found

- Reaction validation did not fully validate categories, pressure states, cooldown values, repeat limits, display names, or descriptions.
- Execution bridge validation did not reject unsafe payload values such as Instances, callbacks, threads, overly deep data, or oversized metadata.
- Cooldowns and reaction memory were applied before execution bridge acceptance, which could leave a failed reaction looking active.
- Invalid preferred categories could influence selection instead of being ignored safely.
- Pressure changes could jump too abruptly from one state to another.
- Zone pressure state had no stale-entry cleanup.
- Diagnostics had memory data, but recent decisions and suppression context needed to be stronger.
- Self-checks did not cover cooldown deferral or unsafe execution payload rejection.

## Fixes Made

- Strengthened reaction registry validation for category, pressure states, cooldowns, repeat limits, names, and descriptions.
- Added valid reaction category definitions to the shared type module.
- Hardened execution bridge payload validation and guaranteed it still only publishes EventBus instructions.
- Moved cooldown and reaction-memory recording after execution bridge acceptance.
- Added bounded recent decision memory.
- Added stale zone pressure cleanup.
- Added pressure transition validation to suppress abrupt non-release jumps.
- Ignored invalid preferred categories instead of treating them as real categories.
- Expanded self-checks for cooldown deferral and unsafe payload rejection.
- Updated docs to clarify audit behavior and future execution boundaries.

## Remaining Risks

- The selector is deterministic. Future phases may add seeded variation to reduce predictability while preserving reproducibility.
- Conflict policy with future Narrative, Performance, Puzzle, and Monster Directors is still foundation-level.
- The execution bridge only publishes contracts; future physical systems still need their own validation and cleanup.
- Self-checks are useful runtime checks, not a full automated test harness.

## Chapter 1 Guidance

Chapter 1 should feed trusted observations into the Observation Engine with zone metadata such as `zoneId`, `zoneKind`, party size, and context tags. It should request environment reactions through the DirectorCoordinator instead of directly changing fog, rain, doors, or props.

## Future Execution Systems

Future physical execution systems should listen for `EnvironmentDirector.ExecutionRequested`, validate the requested chapter object exists, validate the request is still relevant, apply only the approved execution kind, and fail closed if anything is missing. They must not interpret pacing or invent new horror beats.

## Spam Avoidance

The Environment Director avoids random scare spam through cooldowns, repeat limits, pressure-state gates, zone gates, safe-room protection, puzzle/chase fairness checks, bounded memory, and the ability to choose silence.

## Fairness Rules

- `SafeRoomProtection`: prefer release and suppress pressure that would violate a future safe area.
- `PuzzlePressure`: never obstruct puzzle truth or hide required information unfairly.
- `ChaseSupport`: support readability and escape flow; do not block escape.
- `ReleaseSupport`: use silence, rain softening, and reduced pressure when players are overwhelmed.
