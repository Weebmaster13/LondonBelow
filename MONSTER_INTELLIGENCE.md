# Monster Intelligence Foundation

Phase 15 creates the server-authoritative layer that decides why a monster would care, wait, observe, investigate, coordinate, search, pressure, or leave.

It does not implement Monster AI. It does not create NPCs, navigation, pathfinding, attacks, animations, sounds, lighting, client remotes, Workspace mutation, Chapter 1 content, or final scares.

## Golden Flow

Trusted server facts enter the Observation Engine. Directors coordinate pacing and permissions. Monster Intelligence turns approved context into explainable intentions. Future Monster AI may later execute approved intentions, but it must never decide intent by itself.

## Owns

- Knowledge and believed facts.
- Decaying memory.
- Interest, curiosity, patience, territory, search, and threat scores.
- Claimed investigations and shared knowledge.
- Decision confidence, reasons, and bounded decision history.
- Diagnostics, snapshots, and self-check evidence.

## Does Not Own

- Movement, pathfinding, navigation, physics, attacks, damage, animation, sounds, Lighting, Workspace, client visuals, remotes, or gameplay content.

## Runtime Modules

- `MonsterIntelligenceCoordinator`: lifecycle and public API.
- `MonsterMind`: intent decision from scoring context.
- `MonsterRegistry`: abstract monster definitions.
- `MonsterState`: state, interest, and decision records.
- `MonsterMemory`: bounded decaying remembered events.
- `MonsterKnowledge`: believed fact state.
- `MonsterValidator`: ids, confidence, interest, state transition, and unsafe request validation.
- `MonsterDiagnostics`: health, counts, and inspection summaries.

## Canon Rules

The system follows the London Bible: the main entity should feel patient, intelligent, and cruelly curious, but it must not own all horror pacing. Monster Intelligence can decide intent. Future Monster Director and Monster AI work must preserve that split.

## Deferred Work

- Monster Director approvals.
- Monster AI movement and perception execution.
- NPC models and animation controllers.
- Chapter-specific monster archetypes.
- Real Studio adapters.
