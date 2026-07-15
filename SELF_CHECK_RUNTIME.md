# Self-Check Runtime

London Engine self-check execution is intentionally separated from certification. A phase is not Production Certified unless the self-check runtime executes the required checks and reports zero failures.

Run Phase 109 self-checks with:

```powershell
npm run london:selfchecks:phase109
```

## Detection Order

The runtime abstraction checks, in order:

1. local bundled Luau runtime;
2. local Lune runtime;
3. Roblox CLI;
4. no runtime available.

If no runtime is available, the report status is `Runtime unavailable`, no self-check execution is claimed, and certification remains incomplete.

For Phase 109, the Chapter 0 Home modules use Roblox APIs. If no standalone Luau/Lune/Roblox CLI runtime is available, the correct next action is Roblox Studio execution through the Studio-only runner below.

## Bundled Luau

Place a Luau executable at one of:

```text
automation/runtime/luau.exe
automation/bin/luau.exe
tools/luau/luau.exe
```

On non-Windows systems, use the same paths without `.exe`.

The harness must remain deterministic and local-only. It may use mocks for Roblox APIs when tests do not require live Roblox services.

## Lune

Install Lune and ensure `lune` is on `PATH`, then run:

```powershell
npm run london:selfchecks:phase109
```

The Phase 109 local harness is:

```text
automation/local-state/phase109-selfchecks.luau
```

`automation/local-state` is ignored because the harness is a local verification adapter, not gameplay source.

## Roblox CLI

If using Roblox CLI, ensure `roblox-cli` is on `PATH`. The automation will detect it after bundled Luau and Lune. Roblox CLI execution must still produce exact totals and failures before certification can be claimed.

## Roblox Studio Phase 109 Runner

Roblox Studio is the authoritative runtime when standalone Luau/Lune execution is unavailable.

The runner is a ModuleScript, not an auto-running server Script:

```text
ServerScriptService.Chapter0Home.Studio.Phase109SelfCheckRunner
```

It is gated by:

- `RunService:IsStudio()`;
- explicit Workspace attribute `LondonPhase109RunSelfChecks = true`;
- manual invocation from Studio.

It does not run automatically in production servers.

To run it in Roblox Studio:

1. Open the Rojo-synced place in Roblox Studio.
2. Ensure Rojo has synced the current repository source.
3. In the Studio Command Bar, run:

```lua
workspace:SetAttribute("LondonPhase109RunSelfChecks", true)
local runner = require(game.ServerScriptService.Chapter0Home.Studio.Phase109SelfCheckRunner)
runner.run()
workspace:SetAttribute("LondonPhase109RunSelfChecks", false)
```

The runner prints:

- suite name;
- total checks;
- passed checks;
- failed checks;
- each failure message;
- final `PASS` or `FAIL`.

It errors if any self-check fails. Do not mark Phase 109 Production Certified unless the runner reports final `PASS` with zero failures.
