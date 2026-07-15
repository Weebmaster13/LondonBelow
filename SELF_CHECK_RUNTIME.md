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
