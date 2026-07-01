# London Below Roadmap

London Below is the first shipped experience using London Engine. The current roadmap is governed by `LONDON_ENGINE.md` and `ENGINE_CONSTITUTION.md`.

The current milestone is Phase 15.5: Horror Orchestration Framework.

Future phases must preserve both `ENGINE_CONSTITUTION.md` and the London Bible canon. Monster Intelligence decides intent only; Horror Orchestration coordinates pressure; future Monster AI executes approved intentions and must not own intent.

The current forward implementation order is:

1. Phase 5: London Engine Governance Layer
2. Phase 6: Director Ecosystem Contracts
3. Phase 7: Environment Director Foundation
4. Phase 8: Environment Director Audit and Hardening
5. Phase 9: Simulation and Validation Framework
6. Phase 10: World Intelligence Specification
7. Phase 11: Lighting Director + Audio Director Foundations
8. Phase 12: Lantern + Darkness Systems
9. Phase 13: Gameplay Intelligence Framework
10. Phase 14: Gameplay Execution Bridge
11. London Bible Foundation: Creative canon source of truth
12. Phase 15: Monster Intelligence Foundation
13. Phase 15.5: Horror Orchestration Framework
14. Phase 16: Monster AI Foundation
15. Phase 17: Save / Journal / Identity Runtime
16. Phase 18: Narrative Runtime
17. Phase 19: Presentation Runtime
18. Phase 20: Chapter 0 Home Vertical Slice

Every phase must preserve the golden flow: trusted server gameplay fact -> Observation Engine -> Director ecosystem -> approved decision -> execution system -> client presentation.

## Phase 1: Engine Foundation

Build the professional runtime spine: Framework, Logger, EventBus, ServiceLocator, Scheduler, RemoteManager, DependencyManager, Diagnostics, and SnapshotManager. Confirm Rojo, VS Code, Studio sync, linting, and build verification stay clean.

Exit criteria: systems can start in order, log clearly, validate dependencies, and expose debugging state without gameplay code depending on ad hoc globals.

## Phase 2: Lobby and Party Flow

Build the server-authoritative lobby, party, queue, matchmaking, ready, chapter selection, and teleport flow.

Exit criteria: players can form a party, ready up, choose or enter a chapter, launch together, recover from failed launch, and receive clear UI feedback.

## Phase 3: Player Controller and Camera

Build client input routing, camera modes, lantern hooks, movement presentation, mobile/keyboard/controller separation, and horror-safe camera behavior.

Exit criteria: client controls feel polished and ready for interaction, UI, lantern, audio, and horror presentation systems.

## Phase 4: Interaction, Inventory, Keys, Doors, Objectives

Build server-authoritative interaction, inventory, keys, doors, objectives, and puzzle-ready state.

Exit criteria: players can interact with world objects, pick up keys, unlock doors, progress objectives, and receive replicated feedback without client trust.

## Phase 5: Horror Director

Build pacing logic for psychological tension, release, ambience, lighting, audio pressure, whispers, fake sounds, and threat windows.

Exit criteria: chapter pressure can rise and fall deliberately without random jumpscare timing.

## Phase 6: Observer System

Build observation of player grouping, hiding, noise, objective progress, lantern use, fear pressure, and vulnerability.

Exit criteria: Horror Director and AI can consume structured observations instead of guessing from scattered scripts.

## Phase 7: Monster AI

Build the main monster as an intelligent pressure system that stalks, watches, smiles, fake-leaves, returns, learns hiding spots, and sometimes chooses not to chase.

Exit criteria: monster behavior feels scary, fair, original, multiplayer-aware, and director-coordinated.

## Phase 8: Crawler AI

Build crawler creatures that scout, harass, mislead, and alert the main monster.

Exit criteria: crawlers add tension and information flow without replacing the main monster.

## Phase 9: Simulation and Validation Framework

Build a disabled-by-default dev lab that proves Observation Engine, Director Ecosystem, Environment Director, Governance, Player Runtime hooks, diagnostics, snapshots, and decision traces can work together before gameplay content exists.

Exit criteria: required synthetic scenarios produce structured reports, invalid observations are rejected, failed execution bridge requests do not create cooldowns, stale zone pressure cleans up, memory stays bounded, and simulation shutdown clears simulation-owned state.

Production hardening adds deterministic run IDs, mode validation, failure-safe cleanup, trace evidence checks, and explicit pass/fail criteria per scenario.

## Phase 10: World Intelligence Specification

Define the reusable data model for districts, streets, buildings, floors, wings, rooms, micro-zones, safe rooms, puzzle rooms, chase routes, atmosphere profiles, room personalities, and environmental affordances.

Exit criteria: future Observation, Environment, Lighting, Audio, Monster, and Simulation systems can consume safe spatial context without Chapter 1 content, Monster AI, final scares, or Workspace mutation.

## Phase 11: Lighting Director + Audio Director Foundations

Build server-authoritative sensory approval Directors for visual and sound pressure.

Exit criteria: Lighting and Audio Directors integrate with DirectorCoordinator, Governance, World Intelligence, diagnostics, and snapshots while remaining approval-only with no physical Workspace mutation, no final assets, no client remotes, and no client-owned truth.

Production hardening requires unknown zones to stay conservative, safe rooms and puzzle rooms to suppress hostile pressure, invalid explicit sensory request kinds to reject, and deferred or rejected requests to avoid cooldown creation.

## Phase 12: Lantern + Darkness Systems

Build reusable server-authoritative lantern usage and darkness exposure truth.

Exit criteria: clients can request lantern toggle only, server owns lantern/darkness truth, required observations are emitted, safe rooms and puzzle rooms are protected, Director requests are approval-only, and no final effects/content are added.

Production hardening adds lantern request replay protection, spoofed-equipped rejection, untrusted client-zone handling, bounded diagnostics, observation cooldowns, Director request throttles, and unknown-zone fail-protected behavior.

## Phase 13: Gameplay Intelligence Framework

Build the reusable gameplay truth layer for objects, doors, inventory, keys, objectives, graph-based puzzles, puzzle hints, gameplay memory, diagnostics, observations, and Director approval hooks.

Exit criteria: reusable data-driven runtime modules exist, clients own no gameplay truth, duplicate ids reject, invalid door transitions reject, key unlock flow works in data only, objective progress validates, puzzle graphs validate, impossible graphs reject, memory is bounded, shutdown clears state, and no Chapter 1 content or Workspace mutation is added.

## Phase 14: Gameplay Execution Bridge

Build the dry-run server-only execution boundary between gameplay truth and future physical or presentation adapters.

Exit criteria: execution requests validate, queue, expire, lock per object, reject duplicate IDs, reject unknown kinds, reject missing targets, expose diagnostics/snapshots, register adapter contracts, default to dry-run, and do not mutate Workspace.

Production hardening adds bounded execution history, adapter `pcall` isolation, missing-adapter safe deferral, stronger self-checks, and explicit proof that dry-run does not mutate Workspace or gameplay truth.

## London Bible Foundation

Create `LONDON_BIBLE/` as the professional creative design bible for London Below.

Exit criteria: story, vision, Building, entities, gameplay meaning, world language, chapter outlines, and engine integration canon have focused Markdown outlines with open design questions instead of invented contradictions. Future technical phases preserve both the Engine Constitution and Bible canon.

## Phase 15: Monster Intelligence Foundation

Build the server-authoritative reasoning layer for monster intent.

Exit criteria: monster memory, knowledge, interest, curiosity, patience, territory, search priority, shared claims, diagnostics, snapshots, and self-checks exist without Monster AI, navigation, pathfinding, NPCs, Workspace mutation, client remotes, Chapter 1 content, or gameplay implementation.

## Phase 15.5: Horror Orchestration Framework

Build the cross-system coordination layer for horror pressure.

Exit criteria: pressure budget, silence decisions, release decisions, scare eligibility, chase preparation recommendations, emotional beat protection, approval-only coordination bundles, diagnostics, snapshots, self-checks, and Governance contract exist without Monster AI, navigation, Workspace mutation, client remotes, sounds, Lighting changes, final scares, or chapter content.

## Phase 16: Monster AI Foundation

Build future physical monster execution subordinate to Monster Intelligence, Horror Orchestration, Directors, World Intelligence, Observation Engine, and Governance.

Exit criteria: Monster AI executes approved intent without owning intent, pacing, Chapter content, final presentation, or client authority.

## Phase 17: Save / Journal / Identity Runtime

Build server-authoritative save, Journal, memory, identity, and replay truth.

Exit criteria: the Journal remains the player's soul, memories remain identity fragments, and identity percentage can affect future Directors without becoming client-owned truth.

## Phase 18: Narrative Runtime

Build canon-safe narrative beat state, emotional beat protection, chapter progression contracts, and replay-aware story flags.

Exit criteria: narrative systems preserve the London Bible and coordinate with Directors without becoming one-off chapter scripts.

## Phase 19: Presentation Runtime

Build approved client presentation hooks for audio, lighting, UI, camera, screen effects, and accessibility.

Exit criteria: clients present approved truth but never own gameplay, horror, monster, or story truth.

## Phase 20: Chapter 0 Home Vertical Slice

Build the 10 to 15 minute home opening with Mum, Dad, Sister, Marmalade, and the beautiful London apartment after runtime foundations are ready.

Exit criteria: the opening makes the player love the family before horror begins.

## Phase 21: Multiplayer Stress Testing

Validate performance, networking, memory, pacing, and cleanup under multiplayer load.

Exit criteria: the engine survives repeated multiplayer sessions, disconnects, party changes, high observation volume, and Director pressure without leaks or authority regressions.

## Superseded Numbering Note

Older roadmap entries are kept for historical context. The constitution-defined future phase order above is the current source of truth.
