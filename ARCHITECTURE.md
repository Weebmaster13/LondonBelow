# London Below Architecture

London Below is a Rojo-managed Roblox project. The repository source of truth is `src`, and `default.project.json` defines how that source tree appears inside Roblox Studio.

## Rojo Mapping Strategy

`default.project.json` intentionally keeps explicit mappings for the Studio service roots and the planned folder structure.

Rojo can infer non-empty folders from `$path`, but this project currently contains many planned production folders that are intentionally empty except for `.gitkeep` files. Dotfiles are for Git tracking and are not a reliable way to create Studio folders. If the project used only broad `$path` mappings today, many planned folders would not appear when syncing into Roblox Studio.

For that reason, the project file explicitly declares:

- Roblox service roots that must use special classes: `ReplicatedStorage`, `ServerScriptService`, `ServerStorage`, `StarterPlayer`, `StarterGui`, and `Workspace`.
- Special StarterPlayer containers: `StarterPlayerScripts` and `StarterCharacterScripts`.
- Planned empty folders that must exist in Studio before systems are implemented.

This keeps Studio structure stable now, while still allowing future `.lua`, `.model.json`, `.rbxmx`, and asset files to live under their matching `src` folders.

The mapping should be reduced only when folders contain real Rojo-visible files and Rojo can infer them without changing the Studio hierarchy. Until then, the explicit mapping is the safer production choice.

## Engine Layers

London Below should grow as layered engine code, not isolated feature scripts.

Foundation layer:

- `Framework`: boots systems in a predictable order.
- `ServiceLocator`: resolves registered systems without global sprawl.
- `EventBus`: supports process-local events without remotes.
- `Logger`: standardizes diagnostic output.
- `Scheduler`: future frame, interval, deferred, and cleanup orchestration.
- `DependencyManager`: future dependency graph validation and startup ordering.
- `Diagnostics`: future runtime health checks, counters, warnings, and developer reports.
- `SnapshotManager`: future debug snapshots for chapter state, parties, objectives, AI state, and horror pacing.

Networking layer:

- `RemoteManager`: future owner of RemoteEvent and RemoteFunction creation, lookup, validation, rate limits, and contract documentation.
- Remotes live under `ReplicatedStorage/Remotes` or a more specific shared folder such as `ReplicatedStorage/Lobby/PartyRemotes`.

Gameplay layer:

- Lobby, parties, teleporting, inventory, keys, doors, objectives, puzzles, checkpoints, cutscenes, saving, and chapter state are server-authoritative.

Horror layer:

- Horror Director, Fear System, Whisper System, Audio Director, Lighting Director, Building Intelligence, Observer System, monster pressure, and hallucinations coordinate pacing rather than acting as random isolated effects.

AI layer:

- Main Monster AI and Crawler AI are built from perception, memory, behavior, decision-making, navigation, pathfinding, states, communication, emotion, animation, and learning modules.

## Top-Level Services

`ReplicatedStorage`

Shared runtime surface for code and assets that both client and server may reference. Use it for shared modules, remotes, configuration, asset metadata, animations, sounds, and lobby-facing shared definitions.

`ServerScriptService`

Server-only runtime code. Use it for the core framework, AI, gameplay authority, Horror Director, lobby orchestration, saving, utilities, and cross-cutting systems.

`ServerStorage`

Server-owned content that should not replicate by default. Use it for maps, monster templates, and cutscene assets that are spawned or cloned intentionally.

`StarterPlayer`

Client bootstrap containers. `StarterPlayerScripts` holds local controllers for input, UI, camera, audio, effects, horror presentation, and networking. `StarterCharacterScripts` is reserved for character-local client behavior.

`StarterGui`

Source-controlled UI hierarchy. Keep UI structure here when it should be cloned into players' PlayerGui by Roblox.

`Workspace`

World structure that must exist directly in Workspace. Current folders are organizational targets for checkpoints, doors, interactables, hiding spots, triggers, patrol points, puzzles, and spawned monsters. Prefer storing chapter map templates in `ServerStorage/Maps` until they are intentionally loaded.

## Future System Placement

Core engine work belongs in `ServerScriptService/Core` unless it is a shared client/server API, in which case place the shared contract in `ReplicatedStorage/Shared` or `ReplicatedStorage/Modules`.

Lobby and party systems belong in `ServerScriptService/Lobby`; shared lobby configuration and party remotes belong in `ReplicatedStorage/Lobby`.

Inventory, keys, doors, objectives, puzzles, checkpoints, interactions, player run-state, and cutscene orchestration belong in `ServerScriptService/Gameplay`.

Horror pacing belongs in `ServerScriptService/Horror`, split by responsibility: director logic, audio pressure, lighting, hallucinations, fear state, psychology, whispers, and environmental tension.

Monster and crawler AI belong in `ServerScriptService/AI`, split by perception, memory, behavior, decision-making, navigation, pathfinding, states, learning, communication, emotion, animations, and AI utilities.

Persistent progress belongs in `ServerScriptService/Saving`, separated into profiles, checkpoint data, settings, achievements, and statistics.

Client-only presentation belongs under `StarterPlayer/StarterPlayerScripts`: `ClientCore`, `ClientInput`, `ClientUI`, and `ClientHorror`.

## Boundaries

- The server owns gameplay truth.
- The client owns presentation and input.
- Remotes are contracts, not business logic containers.
- `default.project.json` should stay valid JSON and should be verified with Rojo after mapping changes.
- Do not add gameplay systems, monster AI, or placeholder mechanics as part of architecture-only work.

## Current Foundation Review

- `default.project.json` is valid JSON and explicitly maps the required Roblox service classes.
- `AGENTS.md` defines durable AI coding rules and London Below's creative identity.
- `README.md` explains opening, syncing, and verification.
- `.gitignore` excludes Roblox binaries, generated sourcemaps, local verification builds, tooling folders, OS clutter, and logs.
- `selene.toml` and `stylua.toml` provide the current lint/format baseline.
- `.vscode` recommends the Roblox/Rojo development extensions and configures Luau-friendly editor behavior.
- `src/ServerScriptService/Core` contains only starter foundation code. No gameplay systems or monster AI exist yet.
