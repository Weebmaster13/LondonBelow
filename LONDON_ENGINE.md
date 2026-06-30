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

See `ENGINE_GOVERNANCE.md`.

## Final Philosophy

London Engine should make players feel that the world is watching, silence is intentional, the building remembers, the monster is not random, scares are earned, the chapter is reacting, their behavior matters, and every playthrough feels personal.

The monster is not the horror. The Director ecosystem is the horror. The world is the horror. The player's own behavior becomes the horror.
