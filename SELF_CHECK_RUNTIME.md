# Self-Check Runtime

London Engine self-check execution is intentionally separated from certification. A phase is not Production Certified unless the self-check runtime executes the required checks and reports zero failures.

Run Phase 109 self-checks with:

```powershell
npm run london:selfchecks:phase109
```

Run Phase 110 runtime-certification detection with:

```powershell
npm run london:selfchecks:phase110
```

## Detection Order

The runtime abstraction checks, in order:

1. local bundled Luau runtime;
2. local Lune runtime;
3. Roblox CLI;
4. no runtime available.

If no runtime is available, the report status is `Runtime unavailable`, no self-check execution is claimed, and certification remains incomplete.

For Phase 109 and Phase 110, the Chapter 0 Home modules use Roblox APIs. If no
standalone Luau/Lune/Roblox CLI runtime is available, the correct next action is
Roblox Studio execution through the Studio-only runner below.

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

Phase 110 runtime certification intentionally has no committed local harness. The
authoritative runtime evidence is the Studio-gated certification runner because it
must inspect Roblox services, Workspace ownership, RemoteEvents, and RemoteManager
adoption in the actual Roblox runtime.

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

## Roblox Studio Phase 110 Runner

Phase 110 uses the shared Chapter 0 Home Studio certification runner through:

```text
ServerScriptService.Chapter0Home.Studio.Phase110CertificationRunner
```

It is gated by:

- `RunService:IsStudio()`;
- explicit Workspace attribute `LondonPhase110RunSelfChecks = true`;
- manual invocation from Studio.

The Phase 110 runner prints the suite name, totals, passed count, failed count,
setup-failure count, assertion-failure count, each failure with category and reason,
and final `PASS` or `FAIL`. It errors on any failure and restores Chapter0Home
temporary runtime state before returning or failing. Do not mark Phase 110 Production
Certified unless the runner reports final `PASS` with zero failures.

## Phase 118 Certification Review Runner

Phase 118 uses:

```text
ServerScriptService.Chapter0Home.Studio.Phase118CertificationRunner
```

Gate:

```text
Workspace.LondonPhase118RunCertification = true
```

The runner is Studio-only, explicit-gate only, and rejects concurrent runs through
`Workspace.LondonPhase118CertificationActive`. It returns isolated structured
evidence and separates runtime unavailable, gate missing, setup failure, assertion
failure, cleanup failure, upstream failure, skipped execution, and successful
authoritative execution. Static local wrapper checks may report Roblox Studio
required, but that is not a passing runtime result.

## Phase 119 Certification Hardening Wrapper

Phase 119 uses the same Studio-authoritative runner because it hardens Phase 118
certification evidence rather than adding a new runtime:

```powershell
npm run london:selfchecks:phase119
```

When no standalone Luau, Lune, or Roblox CLI runtime is available, the wrapper
writes `automation/local-state/phase119-selfcheck-runtime-report.md`, exits
nonzero, and reports Roblox Studio required. This is truthful deferred execution,
not a failure of static validation and not a certification pass.

## Phase 120 Evidence Capture Wrapper

Phase 120 uses the same Studio-authoritative runner identity because it captures
evidence for the Phase 118/119 certification path:

```powershell
npm run london:selfchecks:phase120
```

The Phase 120 wrapper writes
`automation/local-state/phase120-selfcheck-runtime-report.md` and remains a local
runtime-availability report only. It does not execute Roblox Studio, does not
produce authoritative suite totals, and does not certify Chapter 0 Home.

## Phase 121 Studio Evidence Capture Command

Phase 121 adds the repository-supported capture command:

```powershell
npm run london:certify:phase120
```

The command verifies source attribution, detects Roblox Studio, writes
deterministic JSON and Markdown evidence under `automation/local-state`, and
returns stable exit codes. It reports `executionBlocked` with exit code `2` when
Studio is present but no supported non-interactive Studio execution and
structured-result capture API is configured.

The command does not duplicate certification logic. Production Certification still
requires authoritative Studio output from
`ServerScriptService.Chapter0Home.Studio.Phase118CertificationRunner`, validated by
`Phase118CertificationContract.validateResult()` and decided by
`Phase118CertificationContract.canProductionCertify()`.

Wrapper self-check coverage is available through:

```powershell
npm run london:certify:phase120:selfcheck
```

## Phase 122 Studio Automation Bridge

Phase 122 adds:

```powershell
npm run london:studio:bridge:phase120
npm run london:studio:bridge:phase120:selfcheck
```

The bridge discovers Studio installations, records version identifiers, classifies
execution support, validates launch arguments, and forwards its status into
`npm run london:certify:phase120`. Launch-only Studio CLI support is not treated as
certification execution because it does not provide structured result capture from
the existing Phase 118 runner.

## Phase 123 Structured Result Capture Detection

Phase 123 extends the bridge with structured capture detection. The bridge
recognizes official Studio MCP command availability, requires repository opt-in,
validates captured-result envelope shape, and keeps `executionBlocked` when no
configured structured capture method is available.
