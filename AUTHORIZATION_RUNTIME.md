# Authorization Runtime

`AuthorizationRuntime` is a thin wrapper around `AssetExecutionAuthorizationCoordinator.registerExecutionAuthorization`.

It registers `ExecutionAuthorization` records only. It does not execute assets, grant authority, route work, dispatch work, schedule work, orchestrate systems, create remotes, mutate Workspace or storage, persist data, or touch gameplay.
