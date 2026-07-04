# Asset Approval Ledger Runtime

Phase 48 adds a server-authoritative, schema-only ledger for formal asset approval evidence after readiness review.

The ledger records approval metadata only. It does not grant execution permission and does not load, preload, stream, spawn, apply, display, play, mutate, or execute assets.

## Owned Schemas

- `ApprovalRecord`
- `ApprovalCondition`
- `ApprovalRevocation`
- `ApprovalAudit`

The coordinator lives at `src/ServerScriptService/AssetApprovalLedger/Core/AssetApprovalLedgerCoordinator.lua`.

## Boundary

Asset Approval Ledger owns approval evidence only. Future execution systems must still pass their own Governance contracts and runtime validation before any asset operation exists.
