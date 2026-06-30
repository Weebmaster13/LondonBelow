# LondonBelow

LondonBelow is a Roblox horror game project organized for professional Rojo-based development.

This repository currently contains only the project foundation: service folders, shared module locations, development tooling configuration, and a small server bootstrap layer. Monster AI, gameplay systems, saving, lobby flow, and horror mechanics are intentionally not implemented yet.

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

## Core Modules

- `Bootstrap.server.lua` starts the server runtime.
- `Framework.lua` coordinates core service registration and startup.
- `Logger.lua` provides scoped logging helpers.
- `EventBus.lua` provides simple in-process publish/subscribe messaging.
- `ServiceLocator.lua` stores and resolves shared server services.

## Development

Install Rojo, then serve the project from the repository root:

```bash
rojo serve default.project.json
```

Run formatting and linting with StyLua and Selene when those tools are available:

```bash
stylua src
selene src
```
