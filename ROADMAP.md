# London Below Roadmap

London Below is the first shipped experience using London Engine. The current roadmap is governed by `LONDON_ENGINE.md` and `ENGINE_CONSTITUTION.md`.

The current milestone is Phase 9: London Engine Simulation and Validation Framework.

The current forward implementation order is:

1. Phase 5: London Engine Governance Layer
2. Phase 6: Director Ecosystem Contracts
3. Phase 7: Environment Director Foundation
4. Phase 8: Environment Director Audit and Hardening
5. Phase 9: Simulation and Validation Framework
6. Phase 10: Audio Director + Lighting Director Foundations
7. Phase 11: Lantern + Darkness Systems
8. Phase 12: Doors, Keys, Objectives, Puzzle Runtime
9. Phase 13: Monster Director
10. Phase 14: Monster AI Foundation
11. Phase 15: Chapter 1 Vertical Slice
12. Phase 16: Cinematic Chase Runtime
13. Phase 17: Chapter 1 Horror Polish
14. Phase 18: Replay Variation + Balancing
15. Phase 19: Save/Checkpoint Hardening
16. Phase 20: Multiplayer Stress Testing

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

## Phase 10: Chapter 1 Vertical Slice

Build one complete chapter from lobby launch to escape/failure with Victorian streets, the main building, objectives, puzzles, checkpoints, crawlers, main monster pressure, and polished horror presentation.

Exit criteria: one serious, replayable, multiplayer horror slice proves the engine.

## Phase 10: Polish and Optimization

Profile and improve performance, network budgets, lighting, audio mix, mobile UX, accessibility, memory cleanup, error handling, save reliability, and content polish.

Exit criteria: the project can expand beyond Chapter 1 without foundation rewrites.

## Superseded Numbering Note

Older roadmap entries are kept for historical context. The constitution-defined future phase order above is the current source of truth.
