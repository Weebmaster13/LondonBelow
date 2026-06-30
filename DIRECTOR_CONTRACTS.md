# Director Contracts

Every Director must implement the stable lower-case interface validated by `ServerScriptService/Core/Directors/DirectorContract.lua`.

Required methods:

- `initialize()`
- `start()`
- `shutdown()`
- `observe(observation)`
- `requestApproval(request)`
- `cancelRequest(requestId, reason)`
- `getCapabilities()`
- `getHealth()`
- `getSnapshot()`
- `getDiagnostics()`
- `validate()`
- `describe()`

## Rules

- A Director owns one interpretation domain.
- A Director advertises explicit capabilities.
- A Director exposes diagnostics and snapshots.
- A Director can be replaced without rewriting the Coordinator.
- A Director interprets observations and requests approvals; it does not execute gameplay.
- A Director does not directly call or mutate another Director.
- A Director must fail safely when data is missing or stale.

## Description Shape

`describe()` returns the Director name, display name, responsibilities, non-ownership boundaries, and capabilities. This description is used by registration, diagnostics, governance, and future developer inspection tools.

## Future Director Registration

Future Directors should satisfy this contract and register through `DirectorCoordinator.registerDirector`. They should also add a Governance contract before becoming production systems.
