# Execution Adapter Review

Phase 14 includes an adapter registry and adapter contract, but no real adapters.

## Adapter Contract

Future adapters must provide:

- `canApply(request)`
- `apply(request)`
- `rollback(request)`
- `getHealth()`
- `getDiagnostics()`
- `describe()`

Registration rejects adapters missing any required method.

## Adapter Safety

The router isolates adapter calls with `pcall`. If `canApply` or `apply` throws, the request fails safely. If `apply` fails, rollback is attempted with `pcall`.

Adapter diagnostics are also isolated. A broken `describe`, `getHealth`, or `getDiagnostics` method cannot break bridge diagnostics.

## Future Adapter Rules

- Adapters must not create gameplay truth.
- Adapters must not bypass GameplayExecutionValidator.
- Adapters must not bypass Director approval metadata for major execution kinds.
- Adapters must expose meaningful health and diagnostics.
- Adapters must define rollback behavior, even if rollback is a safe no-op.
- Real Workspace adapters require a future production audit before enabling physical mutation.
