# London Below Task Backlog

This task list is the intended production build order. Do not jump ahead unless the user explicitly asks.

## Constitutional Rule

Future tasks are London Engine tasks. They must follow `LONDON_ENGINE.md`, `ENGINE_CONSTITUTION.md`, and the golden flow: trusted server gameplay fact -> Observation Engine -> Director ecosystem -> approved decision -> execution system -> client presentation.

## Completed Foundation

- Phase 1: Core Runtime foundation.
- Phase 2: Lobby and Party Flow.
- Phase 2.5: Cinematic Portal Runtime and Studio integration planning.
- Phase 4 foundation: Observation Engine.
- Psychological Horror Director foundation.

## Phase 5: London Engine Governance Layer

- Build governance contracts, validation, scorecards, diagnostics, and snapshots.
- Register current major system contracts.
- Make future subsystem architecture explicit before gameplay grows.

## Phase 6: Director Ecosystem Contracts

- Define Director contracts for Narrative, Story, Environment, Lighting, Audio, Music, Monster, Puzzle, Save, Difficulty, and Performance Directors.
- Document what each consumes, publishes, owns, and explicitly does not own.
- Ensure major horror events require Director approval.

## Phase 7: Environment Director Foundation

- Build environment reaction contracts for fog, rain, doors, props, building behavior, and room pressure.
- Consume Observation Engine context and Director decisions.
- Do not add Chapter 1 content yet.

## Phase 8: Audio Director + Lighting Director Foundations

- Build sound pressure and visibility pressure foundations.
- Keep client effects presentation-only and server-approved.

## Phase 9: Player Controller + Interaction Foundation

- Add client input/controller architecture and server-authoritative interaction facts.
- Emit observations for movement, looking, interaction, and hesitation.

## Phase 10: Lantern + Darkness Systems

- Build lantern and darkness truth with observations, Director approvals, and presentation-only client effects.

## Phase 11: Doors, Keys, Objectives, Puzzle Runtime

- Build server-owned doors, keys, objectives, and puzzle contracts.
- Route puzzle and objective facts through Observation Engine.

## Phase 12: Monster Director

- Build monster permission, reveal, stalk, chase, fake-leave, linger, retreat, and no-action decisions.

## Phase 13: Monster AI Foundation

- Build Monster AI subordinate to Monster Director and Horror Director.
- Own movement, perception, pathfinding, attacks, animation state, and physical behavior only.

## Phase 14: Chapter 1 Vertical Slice

- Build one polished chapter loop only after the engine Directors and gameplay foundations exist.

## Phase 15: Cinematic Chase Runtime

- Build director-approved cinematic chase flow.

## Phase 16: Chapter 1 Horror Polish

- Polish audio, lighting, ambience, fog, presentation, scares, and pacing.

## Phase 17: Replay Variation + Balancing

- Add variation and tuning based on Observation Engine and Director diagnostics.

## Phase 18: Save/Checkpoint Hardening

- Harden persistence, recovery, disconnect behavior, and checkpoint rules.

## Phase 19: Multiplayer Stress Testing

- Validate performance, networking, memory, pacing, and cleanup under multiplayer load.

## Legacy Completed Phase Notes

### Phase 1: Core Engine

- Harden service startup, lifecycle, logging, dependency lookup, and event dispatch.
- Maintain Scheduler, RemoteManager, DependencyManager, Diagnostics, and SnapshotManager as the core grows.
- Add shared constants and typed contracts for server/client communication.
- Establish testing, linting, and verification habits before gameplay systems expand.

### Phase 2: Lobby and Party Flow

- Build server-authoritative parties, ready states, chapter selection, and launch flow.
- Add client UI for party state and launch feedback.
- Keep shared lobby config and party remotes under `ReplicatedStorage/Lobby`.

### Original Phase 3: Player Controller and Camera

- Add client input routing, camera state, movement presentation hooks, and horror-friendly camera constraints.
- Keep server authority over gameplay-impacting movement and chapter state.
- Prepare lantern, breathing, heartbeat, and screen effect integration points without implementing scare logic prematurely.

### Original Phase 4: Interaction, Inventory, Keys, Doors, Objectives

- Build server-owned interaction, key, inventory, locked-door, and objective state.
- Add puzzle-friendly objective contracts.
- Replicate only the client-facing state needed for prompts, UI, and feedback.

### Original Phase 5: Horror Director

- Build the pacing controller for tension, release, ambience, and threat pressure.
- Coordinate lighting, audio, whispers, fake sounds, crawler pressure, and monster opportunities.
- Avoid random jumpscare spam.

### Original Phase 6: Observer System

- Track player location, grouping, hiding, light use, noise, objective progress, and vulnerability.
- Feed observations into the Horror Director and later Monster AI.
- Keep observation server-authoritative where it affects gameplay.

### Original Phase 7: Monster AI

- Build the main monster around stalking, watching, fake-leaving, selective pursuit, memory, and hiding-spot learning.
- Keep behavior fair, readable, original, and multiplayer-safe.

### Original Phase 8: Crawler AI

- Build smaller crawler creatures that scout, pressure, misdirect, and alert the main monster.
- Use crawlers to create tension and information flow, not cheap random damage.

### Original Phase 9: Chapter 1 Vertical Slice

- Build one polished chapter loop from lobby entry to escape or failure.
- Include Victorian London streets, the main building, objectives, puzzles, checkpoints, crawler pressure, Horror Director pacing, and the first main-monster encounter.
- Use the vertical slice to prove performance, multiplayer flow, atmosphere, and production standards before expanding content.

### Original Phase 10: Polish and Optimization

- Add save/checkpoint hardening, accessibility, mobile polish, audio mixing, lighting optimization, network budget reviews, memory cleanup, and QA passes.
- Optimize after profiling, but fix obvious scalability risks immediately.
