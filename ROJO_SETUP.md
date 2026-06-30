# Rojo Setup

## Tools

Install or verify:

- Git
- VS Code
- Rojo
- Roblox Studio
- Rojo Studio plugin
- StyLua
- Selene
- Luau LSP / Roblox LSP VS Code extensions

## Open the Repository

```powershell
cd C:\Users\nzomo_dx4jmc8\Documents\GitHub\LondonBelow
code .
```

Accept the recommended VS Code extensions.

## Start Rojo

```powershell
rojo serve default.project.json
```

Rojo will print a local server URL, usually:

```text
http://localhost:34872/
```

## Connect Roblox Studio

1. Open Roblox Studio.
2. Open or create the development place.
3. Open the Rojo plugin.
4. Connect to the local Rojo server.
5. Confirm the mapped services appear: ReplicatedStorage, ServerScriptService, ServerStorage, StarterPlayer, StarterGui, and Workspace.

## Verify Mapping

```powershell
rojo sourcemap default.project.json --output sourcemap.json
Remove-Item -Force sourcemap.json
rojo build default.project.json --output rojo-verify.rbxlx
Remove-Item -Force rojo-verify.rbxlx
```

Do not commit generated place files. Rojo source stays in `src`.

## Why the Project File Is Explicit

London Below has a large planned Studio hierarchy before most systems exist. Rojo cannot infer empty Studio folders from Git-only `.gitkeep` files. `default.project.json` explicitly declares the hierarchy so Studio sync is stable now and remains predictable as systems are added.
