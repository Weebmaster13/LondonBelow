# London Engine Constitution

This is the highest-level architecture law for London Engine and London Below.

When this document conflicts with older docs, this document wins unless the user gives newer, explicit direction.

## Article 1: Engine First

London Engine is a reusable Roblox psychological horror engine. London Below is its first shipped game.

Every future feature, chapter, monster, puzzle, scare, UI, save system, lobby transition, and gameplay mechanic must be built as part of the engine architecture. One-off scripts are forbidden for production systems.

## Article 2: Golden Flow

Every meaningful gameplay event follows:

```text
Trusted Server Gameplay Fact
-> Observation Engine
-> Director Ecosystem
-> Approved Decision
-> Execution System
-> Client Presentation
```

The server owns facts. The Observation Engine owns truth. Directors own interpretation. Execution systems own action. Clients own presentation.

## Article 3: Director Ecosystem

Future Directors must document purpose, ownership, non-ownership, inputs, outputs, integrations, failure cases, diagnostics, and examples.

### Psychological Horror Director

Purpose: fear pacing, tension, silence, scare selection, psychological pressure, and release.

Owns: tension windows, silence decisions, scare opportunity selection, cooldowns, and pressure rhythm.

Does not own: monster movement, story canon, lore delivery, physical doors, final audio playback, final lighting playback, UI, or save data.

Consumes: Observation Engine summaries, player fear profiles, chapter phase, recent decisions, and future Director signals.

Publishes: approved fear pressure, scare opportunities, silence, tension changes, and diagnostics.

Talks to: Audio Director, Lighting Director, Environment Director, Monster Director, Narrative Director, and Performance Director.

Future examples: chooses lantern pressure, approves distant breathing, asks for silence, delays a scare because a player is overwhelmed.

### Narrative Director

Purpose: dramatic pacing, chapter beats, escalation structure, major reveals, and climax readiness.

Owns: dramatic timing, chapter beat progression, reveal eligibility, and tension arc gates.

Does not own: lore content storage, monster pathfinding, UI, player inventory, or save persistence.

Consumes: Observation Engine timelines, objective progress, puzzle completions, party state, Horror Director pressure, and Story Director readiness.

Publishes: beat changes, climax readiness, reveal windows, and chapter phase transitions.

Talks to: Horror Director, Story Director, Monster Director, Puzzle Director, Environment Director, and Save Director.

Future examples: marks the final reveal ready after the party solves a major puzzle and reaches the correct building zone.

### Story Director

Purpose: lore delivery, note timing, dialogue timing, optional fragments, and story clarity.

Owns: when story fragments become available and how lore pacing avoids overload.

Does not own: puzzle validation, objective truth, cutscene execution, or final UI rendering.

Consumes: Observation Engine exploration, note reads, objective progress, party state, and Narrative Director beats.

Publishes: story fragment availability, note timing, dialogue permissions, and lore diagnostics.

Talks to: Narrative Director, Puzzle Director, Audio Director, UI presentation systems, and Save Director.

Future examples: releases an optional note only after players have seen enough environmental clues.

### Environment Director

Purpose: fog, rain, wind, doors, props, world reactions, and building behavior.

Owns: physical world reaction permissions and environmental pressure timing.

Does not own: scare selection, monster movement, puzzle truth, or client-only effects.

Consumes: Observation Engine context, Horror Director pressure, Narrative Director beats, and Performance Director budgets.

Publishes: approved environmental reactions and building-state diagnostics.

Talks to: Lighting Director, Audio Director, Puzzle Director, Monster Director, and execution systems.

Future examples: closes a distant door, thickens fog, shifts props, or makes the building feel attentive.

### Lighting Director

Purpose: darkness, flicker, lamp failures, visibility pressure, silhouettes, shadows, and reveal support.

Owns: visibility pressure and approved lighting state changes.

Does not own: player lantern inventory, monster attacks, or final story beats.

Consumes: Observation Engine darkness/lantern facts, Horror Director decisions, Environment Director state, and Performance Director budgets.

Publishes: lighting instructions and diagnostics.

Talks to: Audio Director, Environment Director, Horror Director, client presentation bridges, and Performance Director.

Future examples: flickers a lantern after overuse, dims a hallway before a reveal, or restores light during release.

### Audio Director

Purpose: whispers, fake footsteps, breathing, ambient pressure, sound deception, silence, and audio cue fairness.

Owns: sound pressure and deception timing.

Does not own: final monster movement, story truth, or client-owned fear state.

Consumes: Observation Engine facts, Horror Director decisions, Narrative Director beats, and Music Director emotional state.

Publishes: approved audio events and diagnostics.

Talks to: Music Director, Horror Director, Environment Director, Monster Director, and client presentation bridges.

Future examples: distant knock after door hesitation, nearby breathing for a hiding player, or deliberate silence after a scare.

### Music Director

Purpose: musical tension, silence, stingers, chase scoring, and emotional arcs.

Owns: music state, stinger permission, chase score intensity, and silence as music.

Does not own: chase state truth, monster attacks, objective validation, or audio deception.

Consumes: Director decisions, chapter phase, chase permissions, and Performance Director budgets.

Publishes: music state changes and diagnostics.

Talks to: Audio Director, Horror Director, Narrative Director, Monster Director, and client presentation bridges.

Future examples: suppresses music to make silence oppressive, starts chase scoring only after Monster Director approval.

### Monster Director

Purpose: monster permission, reveal timing, stalking permission, chase permission, retreat decisions, and monster pressure fairness.

Owns: when monsters are allowed to reveal, stalk, chase, fake leave, linger, retreat, or do nothing.

Does not own: pathfinding, line of sight, attack hitboxes, animation state, or raw movement.

Consumes: Observation Engine patterns, Horror Director pressure, Narrative Director beats, Environment/Audio/Lighting support, and Performance Director budgets.

Publishes: monster permissions, pressure windows, retreat instructions, and diagnostics.

Talks to: Individual Monster AI, Horror Director, Narrative Director, Audio Director, Lighting Director, and Performance Director.

Future examples: allows the monster to watch a hiding player but denies an attack because the player is already overwhelmed.

### Individual Monster AI

Purpose: physical monster behavior.

Owns: movement, perception, pathfinding, attacks, animation state, local state machines, and physical behavior.

Does not own: horror pacing, chapter climax, story reveals, or whether pressure is fair.

Consumes: Monster Director permissions, Observation Engine tactical context, and pathing/perception data.

Publishes: sightings, chase starts, chase ends, lost target, failed path, and performance diagnostics.

Talks to: Monster Director, Observation Engine, Pathfinding, Navigation, Animation, and Performance Director.

Future examples: moves to a reveal point after approval, starts chase only after permission, retreats when ordered.

### Puzzle Director

Purpose: puzzle fairness, puzzle state, hint pacing, pressure safety, and puzzle readability.

Owns: puzzle fairness rules, hint eligibility, failure recovery, and puzzle pressure limits.

Does not own: inventory truth, door animation, monster movement, story canon, or final UI.

Consumes: Observation Engine puzzle attempts, Story/Narrative beats, Horror Director pressure, and player progress.

Publishes: hint permissions, puzzle state diagnostics, and approved puzzle pressure.

Talks to: Gameplay puzzle systems, Story Director, Horror Director, Environment Director, and UI presentation.

Future examples: grants a hint after repeated fair failures, blocks a scare while players are learning a new mechanic.

### Save Director

Purpose: checkpoint rules, profile persistence, chapter progress, recovery, and save safety.

Owns: persistence policy and checkpoint eligibility.

Does not own: DataStore implementation details alone, objective truth, UI, or monster behavior.

Consumes: server-authoritative gameplay state, chapter state, Observation Engine significant events, and Save service results.

Publishes: save decisions, checkpoint eligibility, recovery instructions, and diagnostics.

Talks to: Gameplay systems, Narrative Director, Lobby, Teleporting, and player lifecycle services.

Future examples: allows checkpoint after a safe room, rejects checkpoint during chase, recovers a disconnected player.

### Difficulty Director

Purpose: adaptive tuning, player assistance, challenge scaling, and frustration reduction.

Owns: tuning recommendations and adaptive safety rails.

Does not own: direct monster movement, puzzle answers, client cheats, or save truth.

Consumes: Observation Engine patterns, failure rates, party state, Horror Director pressure, and Performance Director state.

Publishes: tuning recommendations, assistance permissions, and diagnostics.

Talks to: Horror Director, Puzzle Director, Monster Director, Save Director, and Performance Director.

Future examples: slows pressure after repeated failures or raises ambience when players are too comfortable.

### Performance Director

Purpose: budget protection, effect throttling, spawn limits, cleanup pressure, and runtime stability.

Owns: performance budgets and throttling recommendations.

Does not own: creative pacing, story truth, gameplay validation, or player-facing UI.

Consumes: Diagnostics, SnapshotManager, Scheduler, RemoteManager stats, player counts, and system reports.

Publishes: budget pressure, throttle instructions, cleanup requests, and performance diagnostics.

Talks to: every Director and execution system.

Future examples: caps ambience effects on low budget, delays noncritical hallucinations, or requests cleanup of old instances.

## Article 4: Feature Plug-In Law

Every future feature must document:

- Owner system.
- Observations emitted.
- Director approval required.
- Execution system.
- Client presentation allowed.
- Diagnostics required.
- Failure cases.
- Multiplayer rules.

This applies to Chapter 1, chases, monster reveals, crawler enemies, keys, doors, objectives, puzzles, hiding, lantern, darkness, whispers, fake footsteps, fake players, hallucinations, cutscenes, checkpoint saving, chapter endings, lobby transitions, carriage sequence, and cinematics.

## Article 5: Examples

### Door Scare

```text
Player hesitates near door
-> DoorService emits Interaction.DoorHesitation
-> Observation Engine enriches with room, darkness, party separation
-> Horror Director increases tension
-> Environment Director asks permission to close another door
-> Audio Director plays distant knock
-> Client only hears presentation
```

### Monster Reveal

```text
Player solves final puzzle
-> Puzzle system emits Puzzle.Complete
-> Observation Engine records progress
-> Narrative Director marks climax ready
-> Horror Director confirms tension is high enough
-> Monster Director approves reveal
-> Monster AI moves to reveal point
-> Lighting and Audio Directors support the reveal
-> Chase starts only after approval
```

### Lantern Scare

```text
Player overuses lantern
-> Observation Engine detects lantern dependency
-> Horror Director chooses lantern pressure
-> Lighting Director flickers beam
-> Audio Director removes ambient sound
-> Client shows flicker only after server-approved event
```

### Hiding Player

```text
Player hides constantly
-> Observation Engine detects hiding pattern
-> Horror Director chooses pressure, not punishment
-> Audio Director creates nearby breathing
-> Monster Director may make monster linger but not attack
-> Player feels watched
```

## Article 6: Future Implementation Order

The engine should continue in this order unless the user explicitly changes direction:

1. Phase 5: Director Ecosystem Contracts
2. Phase 6: Environment Director Foundation
3. Phase 7: Audio Director + Lighting Director Foundations
4. Phase 8: Player Controller + Interaction Foundation
5. Phase 9: Lantern + Darkness Systems
6. Phase 10: Doors, Keys, Objectives, Puzzle Runtime
7. Phase 11: Monster Director
8. Phase 12: Monster AI Foundation
9. Phase 13: Chapter 1 Vertical Slice
10. Phase 14: Cinematic Chase Runtime
11. Phase 15: Chapter 1 Horror Polish
12. Phase 16: Replay Variation + Balancing
13. Phase 17: Save/Checkpoint Hardening
14. Phase 18: Multiplayer Stress Testing

## Article 7: Codex Rules

Future Codex work must:

1. Read `LONDON_ENGINE.md` first.
2. Treat every task as engine work.
3. Never create one-off gameplay scripts.
4. Never bypass the Observation Engine.
5. Never bypass Director approval for major horror events.
6. Keep Monster AI subordinate to Monster Director and Horror Director.
7. Add documentation for every subsystem.
8. Add diagnostics and snapshot hooks when relevant.
9. Validate and self-review before committing.
10. Run all checks before committing.

## Article 8: Final Philosophy

London Engine should make players feel:

- The world is watching.
- Silence is intentional.
- The building remembers.
- The monster is not random.
- The scares are earned.
- The chapter is reacting.
- Their behavior matters.
- Every playthrough feels personal.
- Every system is coordinated.

The monster is not the horror. The Director ecosystem is the horror. The world is the horror. The player's own behavior becomes the horror.
