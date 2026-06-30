# London Below Task Backlog

This task list is the intended production build order. Do not jump ahead unless the user explicitly asks.

## Phase 1: Core Engine

- Harden service startup, lifecycle, logging, dependency lookup, and event dispatch.
- Maintain Scheduler, RemoteManager, DependencyManager, Diagnostics, and SnapshotManager as the core grows.
- Add shared constants and typed contracts for server/client communication.
- Establish testing, linting, and verification habits before gameplay systems expand.

## Phase 2: Lobby and Party Flow

- Build server-authoritative parties, ready states, chapter selection, and launch flow.
- Add client UI for party state and launch feedback.
- Keep shared lobby config and party remotes under `ReplicatedStorage/Lobby`.

## Phase 3: Player Controller and Camera

- Add client input routing, camera state, movement presentation hooks, and horror-friendly camera constraints.
- Keep server authority over gameplay-impacting movement and chapter state.
- Prepare lantern, breathing, heartbeat, and screen effect integration points without implementing scare logic prematurely.

## Phase 4: Interaction, Inventory, Keys, Doors, Objectives

- Build server-owned interaction, key, inventory, locked-door, and objective state.
- Add puzzle-friendly objective contracts.
- Replicate only the client-facing state needed for prompts, UI, and feedback.

## Phase 5: Horror Director

- Build the pacing controller for tension, release, ambience, and threat pressure.
- Coordinate lighting, audio, whispers, fake sounds, crawler pressure, and monster opportunities.
- Avoid random jumpscare spam.

## Phase 6: Observer System

- Track player location, grouping, hiding, light use, noise, objective progress, and vulnerability.
- Feed observations into the Horror Director and later Monster AI.
- Keep observation server-authoritative where it affects gameplay.

## Phase 7: Monster AI

- Build the main monster around stalking, watching, fake-leaving, selective pursuit, memory, and hiding-spot learning.
- Keep behavior fair, readable, original, and multiplayer-safe.

## Phase 8: Crawler AI

- Build smaller crawler creatures that scout, pressure, misdirect, and alert the main monster.
- Use crawlers to create tension and information flow, not cheap random damage.

## Phase 9: Chapter 1 Vertical Slice

- Build one polished chapter loop from lobby entry to escape or failure.
- Include Victorian London streets, the main building, objectives, puzzles, checkpoints, crawler pressure, Horror Director pacing, and the first main-monster encounter.
- Use the vertical slice to prove performance, multiplayer flow, atmosphere, and production standards before expanding content.

## Phase 10: Polish and Optimization

- Add save/checkpoint hardening, accessibility, mobile polish, audio mixing, lighting optimization, network budget reviews, memory cleanup, and QA passes.
- Optimize after profiling, but fix obvious scalability risks immediately.
