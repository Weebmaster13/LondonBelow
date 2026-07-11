# Authorization Requirement Runtime

`AuthorizationRequirementRuntime` is a thin wrapper around `AssetExecutionAuthorizationCoordinator.registerExecutionAuthorizationRequirement`.

It registers `ExecutionAuthorizationRequirement` records only. Requirements describe metadata obligations for future authorization review and do not grant permissions or execute work.

Phase 86 keeps this wrapper unchanged while hardening requirement validation for exact fields, enum values, ids, ordered evidence and tags, safe metadata keys, and validation-before-mutation.

Phase 87 keeps this wrapper unchanged. Requirement records remain authorization metadata only; integration-readiness declarations do not convert requirements into permission grants or execution obligations.
