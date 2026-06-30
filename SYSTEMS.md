# London Below Systems Architecture

This document defines future system responsibilities. It is not an implementation request by itself.

## Core Engine

The Core Engine is the runtime spine under `ServerScriptService/Core`.

- `Bootstrap`: starts the server runtime and fails loudly when foundation startup fails.
- `Framework`: owns initialization order, start order, and eventual shutdown hooks.
- `Logger`: provides scoped logging for every production system.
- `EventBus`: handles server-process events that do not cross the network.
- `ServiceLocator`: registers and resolves long-lived services.
- `Scheduler`: owns delayed, repeating, deferred, RunService, grouped, and frame-budgeted work.
- `RemoteManager`: owns remote lookup, creation policy, validation hooks, versions, rate limits, middleware, and diagnostics.
- `DependencyManager`: validates startup dependencies, optional integrations, missing modules, and circular dependencies.
- `Diagnostics`: reports health for systems, memory, player counts, startup duration, warnings, and errors.
- `SnapshotManager`: captures engine state now and reserves chapter, party, objective, horror, and AI state for future systems.

Core systems must be boring, deterministic, logged, and testable. They should never contain chapter-specific horror behavior.

## Lobby, Party, and Teleporting

Lobby systems live under `ServerScriptService/Lobby`.

- `Matchmaking`: selects players and chapters for launch.
- `Parties`: creates, joins, leaves, promotes, locks, disbands, and validates parties.
- `Queues`: handles launch queues and retry flow.
- `Teleporting`: owns Roblox teleport calls, reserved servers, failure handling, and return paths.

Shared lobby configuration and party remotes live under `ReplicatedStorage/Lobby`.

## Gameplay Systems

Gameplay systems live under `ServerScriptService/Gameplay`.

- `Interaction`: validates player proximity, prompts, and interaction permissions.
- `Inventory`: stores server-authoritative run inventory.
- `Keys`: manages key ownership, requirements, and consumption policy.
- `Doors`: owns lock state, open state, animations, and server validation.
- `Objectives`: tracks chapter progress and replicated objective hints.
- `Puzzles`: validates puzzle state, clues, solution attempts, and multiplayer cooperation.
- `Checkpoints`: records safe progress and respawn anchors for the current run.
- `Player`: owns run-specific player state, death, revival rules, and chapter participation.
- `Cutscenes`: coordinates server-authoritative sequencing with client presentation.

## Saving

Saving systems live under `ServerScriptService/Saving`.

- `Profiles`: loads and validates persistent player data.
- `CheckpointData`: stores durable progress where the design allows it.
- `Settings`: stores player preferences.
- `Statistics`: stores long-term stats.
- `Achievements`: stores earned milestones.

Saving must fail safely and never trust the client.

## Horror Systems

Horror systems live under `ServerScriptService/Horror`.

- `Director`: owns pacing, escalation, cooldowns, pressure windows, and release.
- `Fear`: tracks fear-relevant player state and chapter pressure.
- `Whispers`: schedules deceptive or truthful whisper moments.
- `Audio`: coordinates heartbeat, breathing, fake sounds, silence, and music pressure.
- `Lighting`: coordinates fog, lantern flicker, darkness, reveal, and visibility pressure.
- `Hallucinations`: controls believable false cues and perception manipulation.
- `Psychology`: models player vulnerability, separation, hiding, and uncertainty.
- `Environment`: coordinates building reactions, room pressure, and environmental warnings.

## AI Systems

AI systems live under `ServerScriptService/AI`.

- `Perception`: sees players, lights, sound sources, crawler alerts, and objective events.
- `Memory`: remembers hiding spots, last known positions, and repeated player choices.
- `DecisionMaking`: selects stalk, watch, chase, fake leave, return, retreat, or wait.
- `Behavior`: executes selected behaviors through state modules.
- `States`: contains explicit state handlers.
- `Pathfinding` and `Navigation`: move monsters within performance budgets.
- `Communication`: lets crawlers alert the main monster and lets AI report pressure to the Director.
- `Emotion`: controls monster personality signals such as smiling, patience, cruelty, and hesitation.
- `Learning`: stores run-local adaptations without making the AI unfairly omniscient.
- `Animations`: coordinates AI animation choices.
- `Utilities`: shared AI helpers only.

## Cutscene System

Cutscenes must not become unskippable debug scripts. The future system should separate:

- Server authority: when a cutscene starts, who participates, and what gameplay is locked.
- Client presentation: camera, UI, sound, animation, fade, subtitles, and local effects.
- Recovery: disconnects, late joins, failed assets, and player death during sequencing.
