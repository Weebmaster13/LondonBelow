# Authorization Runtime

`AuthorizationRuntime` is a thin wrapper around `AssetExecutionAuthorizationCoordinator.registerExecutionAuthorization`.

It registers `ExecutionAuthorization` records only. It does not execute assets, grant authority, route work, dispatch work, schedule work, orchestrate systems, create remotes, mutate Workspace or storage, persist data, or touch gameplay.

Phase 86 keeps this wrapper unchanged. It continues to delegate only to the existing coordinator and gains hardening through shared validation, state isolation, diagnostics, snapshots, and self-checks.
