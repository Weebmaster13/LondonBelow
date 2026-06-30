# London Below

London Below is an original Roblox psychological horror game organized for professional Rojo-based development.

This repository currently contains the London Engine foundation, including Core Runtime, Lobby/Portal runtime, Observation Engine, Director Ecosystem, Psychological Horror Director foundation, Environment Director foundation, Player Experience foundation, Governance, and a dev-only Simulation Validation Framework. Monster AI, Chapter 1 gameplay, final UI/art, and final scare execution are intentionally not implemented yet.

The creative direction is Victorian London horror: foggy streets, a terrifying main building, party-based chapter entry, tense exploration, keys, locked doors, puzzles, checkpoints, escape, and a pacing-driven Horror Director. The project should remain original and should not copy maps, monsters, names, assets, or story from any existing Roblox horror game.

## Project Layout

```text
src/
  ReplicatedStorage/
    Modules/
    Shared/
    Config/
    Assets/
    Animations/
    Sounds/
    Remotes/
  ServerScriptService/
    Core/
    AI/
    Horror/
    Gameplay/
    Lobby/
    Saving/
    Utilities/
    Systems/
  ServerStorage/
    Maps/
    Monsters/
    Cutscenes/
  StarterPlayer/
    StarterPlayerScripts/
    StarterCharacterScripts/
  StarterGui/
  Workspace/
```

See `ARCHITECTURE.md` for the full Studio mapping and folder ownership rules.

## Core Modules

- `Bootstrap.server.lua` starts the server runtime.
- `Framework.lua` coordinates core service registration and startup.
- `Logger.lua` provides scoped logging helpers.
- `EventBus.lua` provides simple in-process publish/subscribe messaging.
- `ServiceLocator.lua` stores and resolves shared server services.
- `Simulation/` contains the disabled-by-default dev validation lab for synthetic engine scenarios.

## Opening the Project

Clone the repository, then open it in VS Code:

```powershell
cd C:\Users\nzomo_dx4jmc8\Documents\GitHub\LondonBelow
code .
```

Install the recommended VS Code extensions when prompted. They include Rojo, Luau LSP, Roblox LSP, StyLua, and Selene.

## Syncing with Roblox Studio

Start Rojo from the repository root:

```powershell
rojo serve default.project.json
```

Open Roblox Studio, open the Rojo plugin, and connect to the local Rojo server shown in the terminal. The usual local address is:

```text
http://localhost:34872/
```

Keep Rojo running while editing files in VS Code. Rojo is the source of truth for project structure and scripts.

## Verification

Before committing normal source changes, run:

```powershell
rojo sourcemap default.project.json --output sourcemap.json
Remove-Item -Force sourcemap.json
stylua src
selene src
```

For mapping changes, also run a build verification:

```powershell
rojo build default.project.json --output rojo-verify.rbxlx
Remove-Item -Force rojo-verify.rbxlx
```

Generated files such as `sourcemap.json`, `.rbxl`, `.rbxlx`, `.rbxm`, and `.rbxmx` should not be committed.

## Roadmap

See `TASKS.md` for the implementation roadmap. The current milestone is Phase 9: Simulation and Validation Framework. Upcoming work should continue engine foundations before Chapter 1, Monster AI, or final presentation.

## Foundation Docs

- `AGENTS.md`: permanent AI coding instructions.
- `ARCHITECTURE.md`: Rojo mapping and engine architecture.
- `SYSTEMS.md`: future system contracts and ownership.
- `CODE_STYLE.md`: Luau, module, logging, and error-handling rules.
- `ROJO_SETUP.md`: Windows, VS Code, Rojo, and Studio sync workflow.
- `GAME_DESIGN.md`: London Below gameplay identity and loop.
- `HORROR_DESIGN.md`: psychological horror rules and pacing.
- `AI_DESIGN.md`: monster, crawler, observer, and building intelligence direction.
- `LOBBY_DESIGN.md`: lobby, party, matchmaking, and launch design.
- `ROADMAP.md` and `TASKS.md`: phase plan and implementation order.
- `SIMULATION_FRAMEWORK.md`: dev-only simulation lab, modes, scenarios, and report shape.
