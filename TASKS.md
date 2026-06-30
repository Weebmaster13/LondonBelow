# London Below Implementation Roadmap

This roadmap is the intended build order for production systems. Do not jump ahead unless the user explicitly asks.

## 1. Core Engine

- Formalize service startup, lifecycle, logging, dependency lookup, and event dispatch.
- Add shared constants and typed contracts for server/client communication.
- Establish testing, linting, and verification habits before gameplay systems expand.

## 2. Lobby/Party System

- Build server-authoritative parties, ready states, chapter selection, and launch flow.
- Add client UI for party state and launch feedback.
- Keep shared lobby config and party remotes under `ReplicatedStorage/Lobby`.

## 3. Inventory/Keys/Doors/Objectives

- Build server-owned interaction, key, inventory, locked-door, and objective state.
- Add puzzle-friendly objective contracts.
- Replicate only the client-facing state needed for prompts, UI, and feedback.

## 4. Horror Director

- Build the pacing controller for tension, release, ambience, and threat pressure.
- Coordinate lighting, audio, whispers, fake sounds, crawler pressure, and monster opportunities.
- Avoid random jumpscare spam.

## 5. Observer System

- Track player location, grouping, hiding, light use, noise, objective progress, and vulnerability.
- Feed observations into the Horror Director and later Monster AI.
- Keep observation server-authoritative where it affects gameplay.

## 6. Monster AI

- Build crawler alert behavior first, then the main monster.
- Implement perception, memory, stalking, fake-leaving, selective chase behavior, hiding-spot learning, and pressure decisions.
- Keep monster behavior original and tuned for fairness, dread, and multiplayer readability.

## 7. Save/Checkpoint System

- Add profile loading, checkpoint progress, settings, statistics, achievements, and safe failure handling.
- Separate permanent player progress from per-run chapter state.
- Validate all save writes on the server.

## 8. Chapter 1 Vertical Slice

- Build one polished chapter loop from lobby entry to escape or failure.
- Include Victorian London streets, the main building, objectives, puzzles, checkpoints, crawler pressure, Horror Director pacing, and the first main-monster encounter.
- Use the vertical slice to prove performance, multiplayer flow, atmosphere, and production standards before expanding content.
