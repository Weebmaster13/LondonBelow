# Director Contracts

Every Director must implement the standard contract:

- `Initialize`
- `Start`
- `Shutdown`
- `Observe`
- `RequestApproval`
- `CancelRequest`
- `GetHealth`
- `GetSnapshot`
- `GetDiagnostics`
- `GetCapabilities`
- `Validate`
- `Describe`

`DirectorContract.lua` validates this shape before a Director is registered.

## Rules

- A Director owns one domain.
- A Director advertises capabilities.
- A Director exposes diagnostics and snapshots.
- A Director can be replaced without rewriting the Coordinator.
- A Director interprets observations and requests approvals; it does not execute gameplay.

Future Directors should be introduced by creating a module that satisfies this contract and registering it with `DirectorCoordinator.registerDirector`.

