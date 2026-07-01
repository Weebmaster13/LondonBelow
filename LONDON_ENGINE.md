# London Engine

London Engine is a reusable Roblox psychological horror engine.

London Below is the first shipped experience built on top of it. The game is Victorian London psychological horror, but the foundation must be strong enough to support Chapter 2, Chapter 5, new monsters, new puzzle types, live updates, multiplayer stress, and future horror experiences without rewriting the runtime.

Every feature must be built as an engine subsystem, not as a one-off script.

## Core Declaration

London Engine exists so horror systems coordinate instead of fighting each other.

- Gameplay systems produce trusted facts.
- The Observation Engine turns facts into knowledge.
- Director systems interpret knowledge.
- Execution systems perform approved actions.
- Clients present the result.

No future task should treat London Below as a pile of scripts. It is a professional engine-backed Roblox experience.

## Creative Canon Foundation

The London Bible now exists under `LONDON_BIBLE/` as the creative canon foundation for London Below. It defines the current source of truth for the player, family, Marmalade, the Building, memory, identity, Journal, horror rules, chapter outlines, and future engine integration expectations.

Future work must preserve both the Engine Constitution and the London Bible. The Constitution protects runtime architecture. The Bible protects story, emotional meaning, originality, and horror identity. If a future system touches story, monsters, puzzles, chapters, UI, audio, lighting, or narrative presentation, Codex should read the relevant Bible files before implementation.

Phase 15 adds Monster Intelligence as the server-authoritative reason layer for monster intent. It owns knowledge, memory, attention, curiosity, patience, territory, shared claims, and explainable intent decisions, but it does not implement Monster AI, navigation, pathfinding, NPCs, Workspace mutation, sounds, Lighting changes, client remotes, or Chapter 1 content.

## Current Engine Stack

### 1. Core Runtime

The Core Runtime is the engine spine under `ServerScriptService/Core`.

- `Framework`: lifecycle, module registration, dependency-aware startup, readiness, and validation.
- `Logger`: scoped logs, context, timers, debug filtering, memory snapshots, buffers, and panic mode.
- `EventBus`: server-process messaging with sync, async, deferred, priority, wildcard, and one-shot listeners.
- `ServiceLocator`: service registration, resolution, replacement, freezing, and dependency graph visibility.
- `Scheduler`: delayed, interval, deferred, Heartbeat, Stepped, Render, group, tag, profiling, and cancellation support.
- `DependencyManager`: required and optional dependency validation, startup graph generation, and circular dependency detection.
- `RemoteManager`: RemoteEvent and RemoteFunction definitions, namespaces, versions, validation, rate limits, and diagnostics.
- `Diagnostics`: health reports, custom samplers, startup duration, memory, player counts, warnings, and errors.
- `SnapshotManager`: structured snapshots for engine state, systems, players, lobby, horror, and future gameplay state.
- `EngineGovernance`: contract registry, constitution validation, scorecards, diagnostics, and snapshots.
- `Bootstrap`: server startup entry point that refuses partial engine startup.

### 2. Lobby Runtime

The Lobby Runtime owns server-authoritative party and launch flow.

- `PartyService`: party truth, membership, leader transfer, ready state, locking, chapter selection, and disconnect cleanup.
- `MatchmakingService`: launch validation and matchmaking handoff.
- `QueueService`: queued launch state and retry protection.
- `TeleportService`: teleport abstraction, disabled/missing-place behavior, reserved server future path, and launch failure recovery.
- `LobbyService`: lobby remotes, server validation, party state broadcasts, launch feedback, diagnostics, and snapshots.

### 3. Cinematic Portal Runtime

The Portal Runtime owns the future physical carriage, fog gate, and chapter door transition.

- `PortalService`: server-authoritative portal orchestration.
- `PortalStateMachine`: explicit portal state transitions.
- `PortalOccupants`: party/solo occupant tracking.
- `PortalCountdown`: countdown lifecycle and cancellation.
- `PortalZoneTracker`: physical zone presence tracking.
- `PortalValidator`: party, leader, ready, chapter, and launch validation.
- `PortalAtmosphere`: future cinematic hook dispatch.
- `PortalZoneBinder`: Studio zone binding from `Workspace/Portals`.

### 4. Observation Engine

The Observation Engine is the sensory nervous system.

- `ObservationService`: intake, validation, routing, enrichment, recording, forwarding, diagnostics, and cleanup.
- `ObservationRegistry`: canonical observation IDs and definition metadata.
- `ObservationValidator`: malformed payload, timestamp, metadata, player, and unknown-type rejection.
- `ObservationContext`: chapter, room, area, weather, lighting, objective, puzzle, proximity, and tag enrichment.
- `ObservationAggregator`: compact counts and high-priority summaries.
- `ObservationMemory`: bounded memory windows and compact counters.
- `ObservationTimeline`: player, party, chapter, monster, and environment timelines.
- `ObservationPatternRecognizer`: patterns and evolving personality confidence.
- `ObservationProfiler`: accepted/rejected/slow observation health counters.
- `ObservationDiagnostics`: validation and inspection aggregation.

### 5. Psychological Horror Director

The Psychological Horror Director is the first Director in the Director ecosystem.

- `HorrorDirector`: lifecycle, scheduled evaluation, Director decisions, EventBus publishing, diagnostics, and snapshots.
- `TensionModel`: per-player and party tension math.
- `PlayerFearProfile`: run-local player fear profiles.
- `ScareRegistry`: metadata-only scare opportunities.
- `ScareSelector`: adaptive scare/silence selection.
- `ScareCooldowns`: global, player, category, and scare cooldowns.
- `DirectorMemory`: recent decision and scare memory.
- `DirectorDiagnostics`: validation and inspection.
- `DirectorSignals`: internal server signal names.

### 6. Director Ecosystem

The Director Ecosystem is the server-only approval and coordination layer under `ServerScriptService/Core/Directors`.

- `DirectorCoordinator`: Director registration, lifecycle, observation routing, request approval, conflict resolution, diagnostics, and snapshots.
- `DirectorTypes`: standard Director, request, approval, capability, and health contracts.
- `DirectorContract`: runtime validation for the standard Director interface.
- `DirectorRegistry`: foundation hierarchy for Psychological Horror, Narrative, Story, Environment, Lighting, Audio, Music, Monster, Puzzle, Save, Difficulty, and Performance Directors.
- `DirectorRouter`, `DirectorRequest`, `DirectorApproval`, `DirectorConflictResolver`, and `DirectorDecisionTrace`: stable request, approval, conflict, and trace infrastructure.

### 6.5 Monster Intelligence Foundation

Monster Intelligence lives under `ServerScriptService/AI/MonsterIntelligence` and decides why a future monster would care.

- `MonsterIntelligenceCoordinator`: lifecycle, diagnostics, snapshots, and public intent API.
- `MonsterMind`: explainable intent selection from bounded scores.
- `MonsterMemory` and `MonsterKnowledge`: decaying memory and believed facts.
- `InterestModel`, `ThreatModel`, `CuriosityModel`, `PatienceModel`, `SearchModel`, `TerritoryModel`, and `InvestigationModel`: pure scoring models.
- `MonsterGroupCoordinator`, `SharedKnowledge`, `ClaimSystem`, and `CompetitionResolver`: future cooperation foundations.

Monster AI must never decide intent. Future physical Monster AI may only execute approved intentions.

This layer does not execute gameplay. It decides whether future execution systems are allowed to act.

### 7. Environment Director

The Environment Director is the first real specialized Director implementation. It lives under `ServerScriptService/Horror/Environment` and replaces the foundation `Environment` domain in the DirectorCoordinator.

- `EnvironmentDirector`: server-only lifecycle, observation intake, Director approval interface, diagnostics, snapshots, and execution bridge handoff.
- `EnvironmentReactionRegistry`: approved reaction definitions and fairness metadata.
- `EnvironmentReactionSelector`: chooses subtle reactions or deliberate silence using pressure, zone, cooldown, repeat, and safety rules.
- `EnvironmentState`, `EnvironmentMemory`, and `EnvironmentZoneContext`: pressure state, bounded memory, cooldowns, and future zone context.
- `EnvironmentExecutionBridge`: validates and publishes future execution requests without mutating Workspace, Lighting, audio, or client UI.

This layer makes the world feel intentional, but it still does not create maps, final effects, monster behavior, or Chapter 1 content.

### 8. Simulation Validation Framework

The Simulation Validation Framework is dev-only infrastructure under `ServerScriptService/Core/Simulation`.

- `SimulationService`: disabled-by-default lifecycle owner and report access.
- `SimulationRegistry` and `SimulationFixtures`: required synthetic scenarios.
- `SimulationScenarioRunner`: controlled synthetic scenario execution.
- `SimulationValidator`: report validation for pressure bounds, bridge failures, stale zones, traces, diagnostics, and memory.
- `SimulationTraceRecorder` and `SimulationReportBuilder`: bounded trace/report output.

Simulation has no client remotes and does not mutate Workspace, create real scares, create Monster AI, create Chapter 1 logic, or alter live player truth. Engine systems must not depend on Simulation.

Simulation remains disabled by default. Reports use deterministic run IDs, bounded traces, explicit pass/fail evidence, diagnostics snapshots, cleanup results, and scenario durations.

### 9. World Intelligence Specification

The World Intelligence layer is a passive contract surface under `ServerScriptService/World`.

- `WorldTypes`: typed vocabulary for districts, streets, buildings, floors, wings, rooms, micro-zones, safe rooms, puzzle rooms, chase routes, atmosphere profiles, room personalities, and affordances.
- `WorldConfig`: conservative defaults for unknown spaces.
- `WorldProfileRegistry`: bounded registration and validation for authored world profiles.
- `WorldZoneContext`: safe world context derivation from observation or director payload metadata.
- `WorldDiagnostics`: lightweight inspection and validation.

World Intelligence does not create maps, mutate Workspace, trigger scares, own Monster AI, own Chapter 1 content, or create client remotes. It tells future Observation, Environment, Lighting, Audio, Monster, and Simulation systems what a space permits.

Unknown zones must remain conservative: no monster reveal, no chase start, no blackout, no major puzzle interruption, and no final scare behavior unless authored profile data and Director approval allow it.

World affordances are permissions, not commands. They can make a future Director request eligible; they cannot execute sound, lighting, monster, or environment behavior by themselves.

### 10. Sensory Director Foundations

The Sensory Director foundations live under `ServerScriptService/Horror/Lighting` and `ServerScriptService/Horror/Audio`.

- `LightingDirector`: approves future dimming, flicker, shadow pressure, visibility pressure, safe-room protection, puzzle-room protection, chase-support lighting, and release lighting.
- `AudioDirector`: approves future whispers, fake footsteps, distant knocks, breathing pressure, heartbeat pressure, silence drops, rain muffling, room ambience, safe-room protection, and puzzle-room protection.

These Directors are approval-only. They do not mutate Workspace, mutate Roblox Lighting, play sound, create final UI/art/scares, create client remotes, or own client truth. Unknown zones, safe rooms, and puzzle rooms are conservative by default through World Intelligence policy.

Production hardening requires invalid explicit sensory request kinds to reject, approved requests to use bounded definition-owned cooldowns, and deferred or rejected requests to avoid creating cooldown state.

### 11. Lantern + Darkness Systems

The Lantern and Darkness systems live under `ServerScriptService/Gameplay/Lantern` and `ServerScriptService/Gameplay/Darkness`.

- `LanternService`: server-owned equipped, on/off, battery hook, low-battery, and overuse truth.
- `DarknessService`: server-owned darkness entry, exit, exposure, and protection truth.

These systems emit Observation Engine facts and request Lighting, Audio, and Environment Director approvals when appropriate. They do not create Chapter 1 content, Monster AI, final UI/art/scares, final lighting effects, final audio playback, or client-owned truth.

Production hardening requires lantern toggles to reject spoofed equipped truth, replayed request IDs, untrusted client zone metadata, and spammy low-battery/overuse/Director paths. Darkness exposure must remain server-owned, throttle observation and Director output, and fail protected in unknown, safe-room, and puzzle-protected spaces.

### 12. Gameplay Intelligence Framework

The Gameplay Intelligence Framework lives under `ServerScriptService/Gameplay`.

- `GameplayCoordinator`: lifecycle, diagnostics, snapshots, memory, and self-checks for reusable gameplay truth.
- `ObjectRuntime`: stable object definitions, allowed states, permissions, observations, and future save hooks.
- `DoorService`: server-owned door state machine for open, closed, locked, barred, puzzle-locked, Director-locked, sealed, disabled, and related states.
- `InventoryService`: server-owned personal inventory truth with party inventory hooks.
- `KeyService`: data-driven key collection, use, master-key, single-use, reusable, party-shared, objective reward, and puzzle reward hooks.
- `ObjectiveService`: reusable primary, secondary, hidden, personal, party, branching, and timed objective truth.
- `PuzzleService`: graph-based puzzle definitions, node dependencies, co-op hooks, fail/completion states, fairness protection, and progressive hints.

This layer does not create Chapter 1 content, Monster AI, final UI/art/scares, physical Workspace mutation, copied puzzles, or client-owned gameplay truth.

Gameplay facts must become Observation Engine facts before Directors interpret them. Future execution systems may act only after Director approval.

### 13. Gameplay Execution Bridge

The Gameplay Execution Bridge lives under `ServerScriptService/Gameplay/Execution`.

- `GameplayExecutionService`: server-only lifecycle, submission, dry-run processing, cancellation, diagnostics, and snapshots.
- `GameplayExecutionQueue`: bounded priority queue with expiration.
- `GameplayExecutionValidator`: source, target, kind, approval, payload, metadata, and expiration validation.
- `GameplayExecutionRouter`: future adapter registry and routing.
- `GameplayExecutionState`: execution records, counters, recent failures, and per-object lock leases.

The bridge is dry-run by default and physical mutation is disabled. It does not own gameplay truth, client presentation, Chapter 1 content, Monster AI, final UI/art/sounds/scares, or Workspace mutation.

Production hardening keeps execution record history bounded, isolates adapter calls, rejects duplicate IDs without corrupting original records, releases locks on cancellation and terminal paths, and preserves dry-run no-mutation behavior.

## The Golden Flow

Every future feature must follow this chain:

```text
Trusted Server Gameplay Fact
-> Observation Engine
-> Director Ecosystem
-> Approved Decision
-> Execution System
-> Client Presentation
```

### Trusted Server Gameplay Fact

A validated fact from a server-authoritative gameplay system. Examples: a player opened a door, entered darkness, solved a puzzle step, separated from the party, or saw a monster. The client can request actions, but the server decides whether the fact is real.

### Observation Engine

The Observation Engine validates, enriches, aggregates, remembers, recognizes patterns, records timelines, and forwards useful knowledge. Ordinary gameplay systems must report here first, never directly to the Horror Director, Monster AI, or story systems.

### Director Ecosystem

Directors interpret truth. They decide pacing, story pressure, fear pressure, world reactions, lighting pressure, sound pressure, monster permissions, puzzle hint timing, save recovery, adaptive balance, and performance protection.

### Approved Decision

An approved decision is a server-owned permission or instruction. It is not a client request and not an effect by itself. It says what may happen, why, who it affects, and what system owns execution.

### Execution System

The execution system performs the action. Door systems move doors. Audio systems play sound. Lighting systems flicker lights. Monster AI moves bodies. Save systems persist state. Execution systems do not invent pacing.

### Client Presentation

Clients render visual, audio, camera, UI, and local effects only after server-approved state. Clients never own truth.

## Responsibility Law

- Observation Engine owns truth.
- Psychological Horror Director owns fear pacing.
- Narrative Director owns dramatic pacing.
- Story Director owns lore timing.
- Environment Director owns physical world reactions.
- Lighting Director owns visibility pressure.
- Audio Director owns sound pressure.
- Music Director owns emotional scoring.
- Monster Director owns monster permission and timing.
- Monster AI owns movement only.
- Puzzle Director owns puzzle fairness.
- Save Director owns persistence.
- Difficulty Director owns adaptive balance.
- Performance Director owns budget protection.

No system may steal another system's responsibility.

## Forbidden Architecture

These are banned unless a future architecture document explicitly justifies an exception:

- Random standalone jumpscare scripts.
- Monster AI deciding when the chapter climax happens.
- Monster AI deciding horror pacing alone.
- Direct client fear state.
- Clients creating trusted observations.
- Chapter scripts triggering major scares without Director approval.
- UI scripts deciding gameplay truth.
- Duplicate remotes outside `RemoteManager`.
- Direct `HorrorDirector` calls from ordinary gameplay systems.
- Direct Monster AI calls from puzzle scripts.
- God scripts.
- Unbounded memory.
- Unvalidated metadata.
- Hardcoded chapter logic inside reusable engine modules.
- Silent failures.
- Feature code without diagnostics.
- Remotes without validation.
- Gameplay systems with no observation output.

## 100000/10 Standard

A system is not 100000/10 because it is large.

A system is 100000/10 when:

- It has one clear job.
- It plugs into the engine cleanly.
- It protects server truth.
- It produces observations.
- It can be inspected.
- It can fail safely.
- It can be extended later.
- It makes future work easier.
- It makes player experience better.
- It avoids rewrites.
- It improves the whole engine.

## Governance Layer

The Governance Layer makes this document enforceable. Future systems declare engine contracts through `EngineGovernance`, and those contracts are validated against the London Engine Constitution.

Governance does not replace code review, tests, or good judgment. It makes architectural responsibilities explicit: who owns truth, who interprets it, who executes it, what diagnostics exist, what cleanup exists, and what failure modes are expected.

Governance exposes a health state, startup validation summary, structured issue severities, and scorecards with pass/fail grades. Production systems cannot be considered ready when diagnostics, snapshots, cleanup behavior, multiplayer guarantees, failure modes, or documentation are empty.

See `ENGINE_GOVERNANCE.md`.

## Final Philosophy

London Engine should make players feel that the world is watching, silence is intentional, the building remembers, the monster is not random, scares are earned, the chapter is reacting, their behavior matters, and every playthrough feels personal.

The monster is not the horror. The Director ecosystem is the horror. The world is the horror. The player's own behavior becomes the horror.
