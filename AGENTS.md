# AGENTS.md

Permanent instructions for all future AI coding work on London Below.

These rules apply to every task in this repository unless the user explicitly gives newer, more specific instructions. Follow the user's direction exactly. Do not rush. Do not add tiny placeholder systems just to make progress. Build production-quality code and keep the repository organized.

## Project Vision

London Below is an original Roblox psychological horror game built with Rojo.

The game should feel realistic, scary, polished, and multiplayer-ready. It can be inspired by the feeling, pacing, and polish of high-quality Roblox horror experiences such as The Mimic, but it must never copy their maps, monsters, names, assets, story, encounter structure, or recognizable creative identity.

The core fantasy is Victorian London under a supernatural pressure:

- Foggy streets, gas lamps, wet stone, narrow alleys, and oppressive darkness.
- A terrifying main building that feels alive, old, and wrong.
- Players gather in a lobby, form a party, and enter chapters together.
- Chapters revolve around keys, locked doors, objectives, puzzles, checkpoints, and escape.
- Horror comes from anticipation, pursuit, misdirection, and atmosphere rather than cheap random jumpscares.
- The main monster toys with players: it stalks, watches, smiles, learns hiding spots, fake-leaves, returns, and sometimes chooses not to chase.
- Smaller crawler creatures create pressure by scouting, startling, blocking paths, and alerting the main monster.
- Whispers, heartbeat, breathing, lantern effects, fake sounds, fog, lighting, and silence should build psychological tension.
- A Horror Director controls pacing and pressure so scares feel authored, reactive, and fair.

## Non-Negotiable Development Principles

- Follow the user's request before making independent design choices.
- Ask for clarification when a decision would materially change the game direction.
- Do not create unfinished placeholder systems unless the user explicitly asks for scaffolding.
- Do not generate generic Roblox template code when a production system is expected.
- Do not create throwaway systems. If temporary code is unavoidable, label it clearly with intent, owner, and removal condition.
- Do not create giant God scripts. Split code by responsibility before it becomes hard to reason about.
- Every real system must be modular, multiplayer-safe, expandable, observable through logging, and defensive around errors.
- Keep all content original: names, lore, puzzles, rooms, monster behavior, assets, dialogue, and story beats.
- Prefer small, focused commits with clear intent.
- Read existing code and repo structure before editing.
- Preserve user changes. Never revert unrelated changes without explicit permission.
- Avoid broad refactors unless required for the task.
- Every system should be scalable for a large multiplayer horror game.

## Production System Rules

Every future production system should define:

- Ownership: server, client, shared, or asset/content.
- Public API: module return shape, remotes, events, configuration keys, and lifecycle hooks.
- Dependencies: services or modules it requires and whether those dependencies are optional.
- Logging: startup, shutdown, important state transitions, validation failures, and unexpected recoverable errors.
- Error handling: invalid input, missing assets, failed DataStore calls, failed pathfinding, disconnected players, and unavailable dependencies.
- Multiplayer behavior: authority, replication, late join, disconnect, race conditions, and exploit resistance.
- Expansion path: how chapter-specific behavior, future monsters, future maps, and tuning changes can be added without rewriting the system.

Do not merge a system that only works for one local test player unless the user explicitly asks for a single-player prototype.

## Folder Rules

Use the current Rojo structure as the source of truth.

`src/ReplicatedStorage`

- `Modules`: reusable modules that are safe for both client and server.
- `Shared`: shared types, constants, utility functions, and interfaces.
- `Config`: tuning values, chapter definitions, monster configuration, objective definitions, and feature flags.
- `Assets`: shared non-sensitive asset references and metadata.
- `Animations`: animation references and animation metadata.
- `Sounds`: sound references and sound metadata.
- `Remotes`: RemoteEvents and RemoteFunctions only. Do not put business logic here.

`src/ServerScriptService`

- `Core`: bootstrap, framework, service registration, logging, and process-level orchestration.
- `AI`: monster AI, crawler AI, perception, pathing, state machines, and behavior trees.
- `Horror`: Horror Director, tension pacing, ambience control, fear events, and scare orchestration.
- `Gameplay`: objectives, interactions, keys, doors, puzzles, checkpoints, chapter flow, and escape rules.
- `Lobby`: lobby, matchmaking, parties, chapter voting, ready states, and party launch.
- `Saving`: player progress, checkpoint persistence, unlocks, and data validation.
- `Utilities`: server-only helper modules.
- `Systems`: cross-cutting server systems that do not fit a more specific folder.

`src/ServerStorage`

- `Maps`: server-owned map models and chapter map containers.
- `Monsters`: server-owned monster rigs, server-only monster assets, and templates.
- `Cutscenes`: server-owned cutscene assets and sequencing data.

`src/StarterPlayer`

- `StarterPlayerScripts`: client runtime scripts for UI controllers, camera, audio, input, and local effects.
- `StarterCharacterScripts`: character-local client behavior only.

`src/StarterGui`

- UI instances and client-facing interface structure.

`src/Workspace`

- Workspace-authored map or placeholder world structure only when Rojo needs it. Prefer chapter maps under `ServerStorage/Maps` until intentionally spawned.

## Coding Standards

- Write Luau that passes StyLua and Selene.
- Use clear module APIs. Return tables from ModuleScripts unless a different pattern is clearly justified.
- Keep modules focused. Avoid giant files that mix unrelated responsibilities.
- Prefer explicit names over abbreviations.
- Avoid magic globals. Use services through `game:GetService`.
- Validate all client requests on the server.
- Use server-authoritative state for gameplay, objectives, monster AI, doors, checkpoints, rewards, and saving.
- Keep client code responsible for presentation, local input, UI, camera, audio, and visual effects.
- Do not store sensitive gameplay truth only on the client.
- Prefer config-driven tuning for monster behavior, pacing, objectives, sounds, lighting, and chapter rules.
- Add comments only where they clarify non-obvious behavior or design constraints.
- Do not add dependencies without a strong reason and user approval when the dependency affects project direction.

## Client and Server Responsibilities

Server owns:

- Lobby and party truth.
- Chapter start, player assignment, checkpoints, and escape state.
- Objective progress, puzzle validation, key ownership, and locked-door state.
- Monster AI, crawler AI, pathing decisions, perception, and chase state.
- Horror Director pacing state and authoritative scare triggers.
- Save data, rewards, unlocks, and anti-exploit validation.
- RemoteEvent and RemoteFunction validation.

Client owns:

- UI rendering and local interface state.
- Camera motion, subtle screen effects, and local post-processing.
- Lantern visuals, local audio layering, heartbeat, breathing, whispers, and fake sounds when instructed by server state.
- Input collection and interaction prompts.
- Cosmetic-only effects that do not decide gameplay truth.

Never trust the client with:

- Objective completion.
- Inventory truth.
- Door unlock truth.
- Monster detection truth.
- Checkpoint or save truth.
- Party membership truth.

## Rojo Workflow

- Use `default.project.json` as the active Rojo project file.
- Keep source files under `src`.
- Do not edit generated Roblox place files as source of truth.
- Do not commit `sourcemap.json` or generated build artifacts.
- Start local sync from the repository root with:

```powershell
rojo serve default.project.json
```

- Verify project structure with:

```powershell
rojo sourcemap default.project.json --output sourcemap.json
Remove-Item -Force sourcemap.json
```

## Git Workflow

- Always inspect status before editing:

```powershell
git status --short --branch
```

- Keep commits focused and intentional.
- Stage only files that belong to the task.
- Use clear commit messages in imperative mood.
- Run relevant checks before committing.
- Push only after local verification passes.
- Never rewrite history, reset hard, or discard user work unless the user explicitly asks.
- If unexpected changes appear, treat them as user work and preserve them.

## Monster AI Philosophy

The main monster should feel intelligent, cruel, and unsettling rather than purely mechanical.

Design goals:

- Stalk before chasing.
- Watch players from partial cover, doorways, windows, stairwells, and fog.
- Smile, pause, or retreat when that is scarier than attacking.
- Learn commonly used hiding spots during a chapter.
- Fake leaving, then return to check corners, lockers, rooms, and dead ends.
- Sometimes choose not to chase so players cannot perfectly predict it.
- React to noise, light, crawler alerts, objective progress, and player separation.
- Pressure groups differently than isolated players.
- Create dread through uncertainty, not unfair instant death.

Avoid:

- Constant full-speed chasing.
- Random teleport scares with no pacing logic.
- Perfect omniscience unless a chapter mechanic explicitly justifies it.
- AI behavior that feels cheap, buggy, or impossible to understand.

## Horror Director Philosophy

The Horror Director is the pacing brain of London Below.

It should:

- Track chapter progress, time since last threat, player fear state, group spread, deaths, hiding, noise, and objective completion.
- Escalate tension with ambience, whispers, footsteps, distant silhouettes, locked-room pressure, and crawler activity.
- Release tension after major scares so the next scare has room to breathe.
- Coordinate monster pressure instead of firing random events.
- Prefer believable cause and effect: sound attracts danger, light reveals safety and risk, progress wakes the building.
- Avoid repetitive scare timing.
- Make multiplayer tension readable without making the experience predictable.

## Lobby and Party Goals

The lobby should become a polished multiplayer entry point.

Future lobby systems should support:

- Party creation and party membership.
- Ready states.
- Chapter selection or chapter voting.
- Safe player gathering space with strong London Below atmosphere.
- Party-only chapter launch.
- Clear feedback when players join, leave, ready up, or fail to launch.
- Server-authoritative party state.

## Gameplay Loop

The intended chapter loop:

1. Players gather in the lobby and form a party.
2. The party enters a chapter together.
3. Players explore foggy Victorian spaces and the main building.
4. Objectives reveal locked paths, keys, puzzles, and danger.
5. Crawlers and environmental cues alert or mislead players.
6. The main monster stalks, studies, separates, and pressures the party.
7. Players solve objectives, use checkpoints, and unlock escape routes.
8. The chapter ends through escape, failure, or a story-specific ending.

Every gameplay system should support this loop unless the user requests a different mode.

## Puzzle System Goals

Puzzles should be atmospheric, readable, and fair.

Future puzzle systems should:

- Support server-side validation.
- Allow clues distributed across rooms, notes, sounds, lighting, props, or environment changes.
- Avoid random guessing as the main solution.
- Support multiplayer cooperation when useful.
- Integrate with keys, locks, objectives, checkpoints, monster pressure, and Horror Director pacing.
- Keep puzzle data configurable per chapter.

## Save and Checkpoint Goals

Saving and checkpoints should be reliable, server-owned, and exploit-resistant.

Future saving systems should:

- Save only validated progress.
- Separate permanent player progress from per-run chapter state.
- Support chapter checkpoints where appropriate.
- Avoid saving temporary client-only state.
- Handle player disconnects and rejoins deliberately.
- Fail safely if data stores are unavailable.

## Networking Rules

- Define remotes intentionally under `ReplicatedStorage/Remotes`.
- Name remotes after actions or events, not implementation details.
- Validate every remote payload on the server.
- Rate-limit sensitive or spam-prone requests.
- Never let clients directly set authoritative state.
- Keep remote payloads small and explicit.
- Prefer server-to-client events for presentation instructions such as audio, camera, UI, and local effects.
- Document remote contracts when adding new networking surfaces.

## Performance Rules

- Design for multiplayer from the start.
- Avoid unbounded loops, runaway task spawning, and per-frame server work unless necessary.
- Use event-driven systems where practical.
- Keep pathfinding and AI perception budgeted.
- Clean up connections, instances, timers, and temporary effects.
- Stream or spawn map and monster assets deliberately.
- Avoid excessive RemoteEvent traffic.
- Keep ambience and visual effects scalable for lower-end devices.
- Profile before optimizing large systems, but do not ignore obvious performance risks.

## Future Roadmap

Build London Below in disciplined phases:

1. Foundation: project structure, core framework, conventions, and durable agent instructions.
2. Lobby and party: party creation, ready state, chapter selection, and launch flow.
3. Chapter framework: loading, player spawning, objectives, checkpoints, failure, and escape.
4. Interaction and objective systems: keys, locked doors, prompts, puzzles, and state replication.
5. Horror Director: tension pacing, ambience, event orchestration, and pressure control.
6. Crawler creatures: scouting, alerting, sound pressure, and environmental harassment.
7. Main monster AI: stalking, watching, hiding-spot learning, fake-leaving, selective chase, and chapter-specific behaviors.
8. Polish pass: lighting, fog, audio, UI, animation, accessibility, performance, and multiplayer feel.
9. Content pass: original chapters, building interiors, Victorian street environments, story fragments, and escape sequences.

Do not jump ahead into later phases unless the user asks for that work.

## Required Checks

Before committing code changes, run the checks relevant to the task. For normal source changes, use:

```powershell
rojo sourcemap default.project.json --output sourcemap.json
Remove-Item -Force sourcemap.json
stylua --check src
selene src
```

If a task changes only documentation, still check Git status and ensure Markdown is readable.

## Definition of Done

A task is done only when:

- The requested behavior or document is implemented.
- The change follows this instruction file.
- Relevant checks have passed or any skipped check is clearly explained.
- The working tree contains only intentional changes.
- The commit, when requested, uses the exact requested message.
- The repository remains ready for future Codex, VS Code, Rojo, and Roblox Studio work.
