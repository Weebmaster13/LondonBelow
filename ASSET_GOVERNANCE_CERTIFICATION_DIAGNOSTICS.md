# Asset Governance Certification Diagnostics

Diagnostics are health-only copied metadata.

Diagnostics expose lifecycle state, counts, limit usage, runtime limits, certification posture, requirement posture, review posture, provider posture, dependency posture, Bootstrap posture, documentation posture, integration posture, integration-readiness posture, validation posture, bounded validation failures, and the last self-check result.

Diagnostics never expose services, Instances, functions, threads, userdata, runtime handles, asset handles, loaded assets, callbacks, listeners, execution adapters, client state, remotes, Workspace references, or mutable internal tables.

Provider and posture keys:

- provider sampler: `assetGovernanceCertificationRuntime`
- provider posture: `assetGovernanceCertificationRuntime`
- certification posture key: `assetGovernanceCertificationPosture`
- integration readiness posture key: `integrationReadinessPosture`
- dependency readiness posture key: `dependencyReadinessPosture`
- Bootstrap readiness posture key: `bootstrapReadinessPosture`
- Governance readiness posture key: `governanceReadinessPosture`
- documentation readiness posture key: `documentationReadinessPosture`
- runtime compatibility posture key: `runtimeCompatibilityPosture`

Phase 62 hardens diagnostics so static runtime metadata from `Types` is copied before exposure. `dependencyPosture`, `bootstrapPosture`, `documentationPosture`, and `runtimeLimits` must not return mutable references to the implementation tables.

Phase 63 adds copied `integrationReadinessDeclarations` metadata. Diagnostics still remain health-only. They do not certify live execution, authorize asset use, create listeners, dispatch signals, attach callbacks, store services, expose adapters, resolve upstream runtime state, repair governance data, or mutate any runtime.
