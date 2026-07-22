# Diagnostics and Evidence

Diagnostics expose `commandBusPosture`, registered command/requester/handler counts, queued/routing/executing/succeeded/cancelled/rejected/failed command counts, queue overflows, idempotency rejects, maximum queue depth, last command id, and last failure.

Snapshots expose command registry, requester registry, handler registry, queue, routing, execution, diagnostics, and evidence snapshots.

Part II adds lifecycle snapshots and deterministic failure categories: `SchemaFailure`, `AuthorizationFailure`, `AuthorityFailure`, `RoutingFailure`, `HandlerFailure`, `QueueFailure`, `ValidationFailure`, `ExecutionFailure`, `CancellationFailure`, and `InternalRuntimeFailure`.
