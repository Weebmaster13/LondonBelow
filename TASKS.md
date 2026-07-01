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
- Phase 8: Environment Director Foundation and audit.
- Phase 9: Simulation and Validation Framework with production hardening.
- Phase 10: World Intelligence Specification and audit.
- Phase 11: Lighting Director + Audio Director Foundations and audit.

## Phase 12: Lantern + Darkness Systems

- Build server-authoritative lantern equipped, on/off, battery hook, and overuse truth.
- Build server-authoritative darkness entered, exited, exposure increased, and protected-zone truth.
- Client may request lantern toggle only.
- Emit required observations through ObservationService.
- Use DirectorCoordinator for future Lighting, Audio, and Environment requests.
- Keep this phase truth-layer only: no Chapter 1, Monster AI, final UI/art/scares, final audio, final lighting effects, or client-owned truth.
- Production hardening must reject spoofed equipped truth, reject replayed lantern toggle request IDs, ignore client zone truth, throttle observations and Director requests, preserve unknown-zone protection, and expand diagnostics/snapshots.

## Completed Phase 11: Lighting Director + Audio Director Foundations

- Build server-authoritative approval foundations for dimming, flicker, shadow pressure, visibility pressure, whispers, fake footsteps, distant knocks, breathing, heartbeat, silence drops, rain muffling, room ambience, and sensory protection states.
- Keep this phase approval-only: no Chapter 1, Monster AI, final UI/art/scares, Workspace mutation, Roblox Lighting mutation, final audio playback, client remotes, or client-owned truth.
- Respect World Intelligence policy for unknown zones, safe rooms, puzzle rooms, chase routes, audio affordances, and lighting affordances.
- Register Governance contracts for both Directors.
- Expose diagnostics and snapshots for recent requests, approvals, rejections, policy suppressions, safe-room suppressions, puzzle suppressions, pressure state, and health.
- Production hardening requires invalid explicit request kinds to reject, unknown zones to stay conservative, and deferred/rejected requests to avoid cooldown creation.

## Completed Phase 10: World Intelligence Specification

- Define reusable spatial contracts for districts, streets, buildings, floors, wings, rooms, micro-zones, safe rooms, puzzle rooms, chase routes, exterior/interior zones, atmosphere profiles, room personalities, and affordances.
- Keep this phase data-model only: no Chapter 1 map, Monster AI, final UI/art/scares, Workspace mutation, or client remotes.
- Provide lightweight typed modules under `ServerScriptService/World`.
- Document how Observation Engine, Environment Director, future Lighting Director, future Audio Director, future Monster Director, and Simulation Framework consume world context.
- Unknown spaces must default to conservative policies that suppress monster reveals, chase starts, blackouts, and unfair puzzle interruptions.
- Affordances are permissions, not actions. They must never execute behavior or bypass Director approval.

## Completed Phase 9: London Engine Simulation and Validation Framework

- Build disabled-by-default synthetic simulation scenarios.
- Validate Observation Engine, Director Ecosystem, Environment Director, Governance, Player Runtime diagnostics, snapshots, and decision traces.
- Do not add Chapter 1, Monster AI, final UI/art, real scares, or Workspace mutation.
- Produce structured reports for required scenarios.
- Keep production hardening requirements current: deterministic run IDs, bounded memory, guaranteed cleanup, real invalid-observation rejection, and no fake pass reports.

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

## Phase 13: Doors, Keys, Objectives, Puzzle Runtime

- Build server-owned doors, keys, objectives, and puzzle contracts.
- Route puzzle and objective facts through Observation Engine.

## Phase 14: Monster Director

- Build monster permission, reveal, stalk, chase, fake-leave, linger, retreat, and no-action decisions.

## Phase 15: Monster AI Foundation

- Build Monster AI subordinate to Monster Director and Horror Director.
- Own movement, perception, pathfinding, attacks, animation state, and physical behavior only.

## Phase 16: Chapter 1 Vertical Slice

- Build one polished chapter loop only after the engine Directors and gameplay foundations exist.

## Phase 17: Cinematic Chase Runtime

- Build director-approved cinematic chase flow.

## Phase 18: Chapter 1 Horror Polish

- Polish audio, lighting, ambience, fog, presentation, scares, and pacing.

## Phase 19: Replay Variation + Balancing

- Add variation and tuning based on Observation Engine and Director diagnostics.

## Phase 20: Save/Checkpoint Hardening

- Harden persistence, recovery, disconnect behavior, and checkpoint rules.

## Phase 21: Multiplayer Stress Testing

- Validate performance, networking, memory, pacing, and cleanup under multiplayer load.

## Completed Phase 6: Player Controller + Interaction Foundation

- Add client input/controller architecture and server-authoritative interaction facts.
- Emit observations for movement, looking, interaction, and hesitation.

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
