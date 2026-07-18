# London Engine Architecture Onboarding

This is the short entry map for engineers joining London Below after Phase 149.
It links to the authoritative sources instead of duplicating the full design
library.

## Start Here

Read in this order:

1. `AGENTS.md`
2. `ENGINE_CONSTITUTION.md`
3. `ENGINE_GOVERNANCE.md`
4. `LONDON_ENGINE.md`
5. `LONDON_ENGINE_MASTER_CONTEXT.md`
6. `ROADMAP.md`
7. `TASKS.md`
8. relevant files under `LONDON_BIBLE/`

## Core Law

Meaningful gameplay follows:

```text
trusted server gameplay fact
-> Observation Engine
-> Director ecosystem
-> approved decision
-> execution system
-> client presentation
```

Do not bypass Observation for gameplay facts. Do not let clients own trusted
truth. Do not treat diagnostics or metadata as runtime evidence.

## Bootstrap

Runtime startup is declared in
`src/ServerScriptService/Core/Bootstrap.server.lua`. A generated projection lives
at `automation/generated/bootstrap-order.json`.

Use:

```powershell
npm run london:architecture:generate
npm run london:architecture-check
```

to refresh and validate the generated architecture maps.

## Governance

Built-in Governance contracts are grouped under:

```text
src/ServerScriptService/Core/Governance/Contracts/
```

`EngineContractRegistry.lua` remains the compatibility facade. `ContractCatalog`
aggregates built-in contracts deterministically and rejects duplicates or
malformed contract tables.

Generated catalog:

```text
automation/generated/engine-contract-catalog.json
```

## Diagnostics And Snapshots

Production subsystems should expose diagnostics and snapshots through the Core
Diagnostics and SnapshotManager patterns. Diagnostics describe health. Snapshots
expose isolated state. Neither is certification evidence by itself.

## Validation And Self-Checks

Generated inventories:

```text
automation/generated/validation-catalog.json
automation/generated/self-check-catalog.json
```

Human-readable command:

```powershell
npm run london:validation-status
```

Self-check definitions are not proof that runtime tests ran. Studio/Luau runtime
execution must be captured truthfully before certification claims can advance.

## Certification Truth

Current certified phase remains Phase 108. Phases 109 through 149 are Production
Candidates. Do not promote any phase without authoritative runtime evidence and
the existing certification authority.

## Chapter 0

Chapter 0 Home lives under:

```text
src/ServerScriptService/Chapter0Home/Core/
```

It is the first playable vertical-slice target. The next recommended phase is
Phase 150: Chapter 0 Home Authoritative Studio Runtime Validation.

## Adding A Subsystem Safely

1. Define ownership and non-ownership.
2. Add a Governance contract.
3. Register in Bootstrap only when runtime startup is required.
4. Add validation, serialization, diagnostics, snapshots, audit, and self-checks.
5. Update docs and generated catalogs.
6. Run static validation.
7. Do not claim runtime evidence unless it actually executed.

## Standard Checks

```powershell
npm run london:architecture:generate
npm run london:architecture-check
npm run london:docs-check
npm run london:contracts-check
npm run london:validation-status
stylua src
stylua --check src
selene src
rojo sourcemap default.project.json --output sourcemap.json
rojo build default.project.json --output rojo-verify.rbxlx
git diff --check
npm run london:status
npm run london:check
```

Delete generated Rojo build artifacts after verification.
