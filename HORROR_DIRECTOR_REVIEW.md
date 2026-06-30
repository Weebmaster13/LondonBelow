# Psychological Horror Director Review

This document records the launch-readiness audit of the documented Psychological Horror Director foundation. The review covers runtime safety, behavior correctness, integration boundaries, and future expansion paths without adding Monster AI, chapter gameplay, final UI, or final art.

## What Was Reviewed

- `HorrorDirector.lua`: lifecycle, observation intake, scheduled evaluation, EventBus publishing, diagnostics, snapshot registration, player cleanup, and public API behavior.
- `HorrorDirectorTypes.lua`: shared type contracts for tension, phases, scare categories, observations, profiles, snapshots, definitions, decisions, and state.
- `HorrorDirectorConfig.lua`: pacing intervals, silence probabilities, thresholds, memory limits, observation weights, and tuning safety.
- `TensionModel.lua`: per-player and party tension math, release state, pressure scoring, and overwhelm soft cap.
- `PlayerFearProfile.lua`: profile creation, trusted observation handling, derived traits, run-local memory, profile inspection, and removal.
- `ScareRegistry.lua`: scare metadata, phase gates, tension gates, requirements, solo/group support, cooldown fields, and validation.
- `ScareSelector.lua`: silence selection, fair scare filtering, cooldown checks, requirement checks, scoring, and blocked diagnostics.
- `ScareCooldowns.lua`: global, player, category, and scare-specific cooldown state.
- `DirectorMemory.lua`: recent decision memory, blocked scare memory, route counts, hiding spot counts, scare counts, and category history.
- `DirectorSignals.lua`: server-only EventBus signal names and future integration signal boundaries.
- `DirectorDiagnostics.lua`: diagnostics capture and validation aggregation.

## Issues Found

- Observation amounts could accept malformed, negative, or extremely large numeric input from trusted server integrations.
- `ScareRegistry.getAll()` and `findById()` exposed internal metadata tables, which future modules could accidentally mutate.
- Player evaluation used random player selection, which made fairness and future tests harder to reason about.
- Selector silence probability used non-deterministic random rolls, making repeated audits harder to reproduce.
- Chapter phase assignment accepted any typed value that matched the Luau annotation at author time, but had no runtime guard.
- Player-specific cooldown timestamps were not cleared when a player left.
- Director shutdown disconnected tasks and signals, but did not clear all run-local memory, profile, and cooldown state.
- Diagnostics validation did not include config, memory, or cooldown validation.
- Director memory validation did not assert that bounded histories stayed within configured limits.
- Registry validation was too shallow for future chapter-authored scare definitions.

## Fixes Made

- Added `HorrorDirectorConfig.validate()` for numeric fields, probabilities, threshold ordering, max tension bounds, and observation weights.
- Added `MaxObservationAmount` and clamped observation amounts in `PlayerFearProfile` to prevent runaway counters from malformed integrations.
- Replaced mutable profile diagnostics with deep snapshot tables for traits and recent lists.
- Added `PlayerFearProfile.clear()` for safe shutdown cleanup.
- Added `ScareCooldowns.removePlayer()`, `ScareCooldowns.reset()`, and stronger cooldown timestamp validation.
- Added `DirectorMemory.reset()` and validation for bounded recent scare, decision, and blocked-scare histories.
- Hardened `ScareRegistry` with copied return values and strict validation for IDs, display names, categories, cooldowns, weights, repeats, tension states, and chapter phases.
- Replaced random player evaluation with deterministic round-robin selection sorted by `UserId`.
- Replaced non-deterministic silence rolls with deterministic rolls derived from player, evaluation bucket, and selector salt.
- Added runtime validation for `HorrorDirector.setChapterPhase()`.
- Hardened observation metadata intake by sanitizing `positionKey` and tag arrays.
- Changed malformed observation handling from assertion failure to logged rejection.
- Expanded `DirectorDiagnostics.validate()` so framework health checks cover config, registry, profiles, memory, and cooldowns.
- Cleared profiles, Director memory, cooldowns, last decision, and evaluation cursor on shutdown.

## Remaining Risks

- Live multi-client tuning still needs Chapter 1 telemetry. The current numbers are safe defaults, not final balance.
- Tension math is intentionally conservative until real objectives, doors, puzzles, hiding spots, crawlers, and monster pressure produce observations.
- `ScareRegistry` contains metadata-only scare hooks. No presentation system exists yet, so selected scare opportunities are not executed.
- No standalone Luau unit test framework exists in the repository yet. Current validation is module-level runtime validation plus StyLua, Selene, Rojo sourcemap, Rojo build, and `git diff --check`.
- Diagnostics providers are registered by name but the current Core diagnostics API does not include unregister hooks. Re-initialization is idempotent in normal Framework startup, but hot reload tooling should add unregister/replace semantics later.

## Chapter 1 Observation Feed Rules

Chapter 1 systems should feed the Director only from trusted server code. Clients may request interactions through validated gameplay remotes, but they must not submit fear state, tension state, scare eligibility, or hidden behavior truth.

Recommended Chapter 1 observation sources:

- Party separation tracker: send `TimeAlone` and `TimeWithParty` on a server cadence.
- Movement/controller system: send `Sprint` when the server accepts sprint state.
- Hiding system: send `Hide` with `metadata.hidingSpotId`.
- Lantern system: send `LanternUse` and `Darkness` from server-validated light/darkness state.
- Door/interactions: send `DoorHesitation` when a player lingers near locked or threatening doors.
- Objective system: send `ObjectiveProgress` as normalized chapter progress.
- Puzzle system: send `PuzzleProgress` as normalized puzzle progress.
- Route tracker: send `Exploration` and stable `positionKey` values for rooms, halls, streets, and building zones.
- Future chase/combat system: send `ChaseSeen` or `ScareSeen` only after server-authoritative encounters.

Observation payloads should be small, stable, and chapter-agnostic where possible. Use stable IDs such as `street.west_alley`, `building.foyer`, or `hiding.foyer_locker_01` instead of display names.

## Future Monster AI Consumption Rules

Monster AI should consume Director decisions later; it should not be implemented inside the Director.

Future Monster AI may subscribe to:

- `HorrorDirector.DecisionMade` for broad pacing awareness.
- `HorrorDirector.ScareSelected` for non-silence opportunity windows.
- `HorrorDirector.SilenceSelected` to understand release windows and avoid constant pressure.
- Future explicit opportunity signals once Monster AI exists.

The Director may later approve opportunities such as watch, stalk, fake leave, return, smile, block path, or choose not to chase. Monster AI must still own movement, perception, pathfinding, line-of-sight, attack rules, and physical state. A Director decision is permission and pacing context, not movement authority.

## Client Effects Must Stay Presentation-Only

Client systems should never decide scare validity, fear levels, objective truth, monster truth, or chapter state.

Allowed future client responsibilities:

- Play heartbeat, breathing, whispers, screen effects, camera pressure, lantern flicker, fake sounds, silence, and audio ducking when instructed by the server.
- Render UI hints and debug state from server-approved decisions.
- Smooth transitions and visual timing locally after receiving a server-owned presentation instruction.

Forbidden client responsibilities:

- Selecting scares.
- Marking players as afraid, overwhelmed, hidden, chased, or isolated.
- Completing objectives or puzzles.
- Triggering Monster AI decisions.
- Bypassing cooldowns or phase gates.

## Audit Result

The Psychological Horror Director remains a foundation system, not a gameplay feature. After this audit it is safer for future Chapter 1 integration because it validates more state, exposes fewer mutable internals, handles malformed inputs defensively, cleans up runtime memory, and produces more reproducible pacing decisions.
