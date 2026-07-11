# Authorization Audit Runtime

`AuthorizationAuditRuntime` is a thin wrapper around `AssetExecutionAuthorizationCoordinator.registerExecutionAuthorizationAudit`.

It registers `ExecutionAuthorizationAudit` records only. Audits summarize copied authorization metadata and do not approve, reject, grant permission, execute assets, or mutate runtime systems.
