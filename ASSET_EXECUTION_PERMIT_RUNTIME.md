# Asset Execution Permit Runtime

Phase 49 adds a server-authoritative, schema-only runtime for future asset execution permit records.

Permits are metadata evidence only. They do not execute, load, preload, stream, spawn, apply, display, play, mutate, or grant client authority.

## Owned Schemas

- `ExecutionPermit`
- `ExecutionPermitScope`
- `ExecutionPermitRestriction`
- `ExecutionPermitAudit`

The coordinator lives at `src/ServerScriptService/AssetExecutionPermit/Core/AssetExecutionPermitCoordinator.lua`.

## Boundary

Asset Execution Permit owns permit metadata only. Future execution runtimes must still perform their own governed validation before any asset operation exists.
