# London Below Roadmap

London Below is the first shipped experience using London Engine. The current roadmap is governed by `LONDON_ENGINE.md` and `ENGINE_CONSTITUTION.md`.

The current forward implementation order is:

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

## Phase 9: Chapter 1 Vertical Slice

Build one complete chapter from lobby launch to escape/failure with Victorian streets, the main building, objectives, puzzles, checkpoints, crawlers, main monster pressure, and polished horror presentation.

Exit criteria: one serious, replayable, multiplayer horror slice proves the engine.

## Phase 10: Polish and Optimization

Profile and improve performance, network budgets, lighting, audio mix, mobile UX, accessibility, memory cleanup, error handling, save reliability, and content polish.

Exit criteria: the project can expand beyond Chapter 1 without foundation rewrites.

## Superseded Numbering Note

Older roadmap entries are kept for historical context. The constitution-defined future phase order above is the current source of truth.
