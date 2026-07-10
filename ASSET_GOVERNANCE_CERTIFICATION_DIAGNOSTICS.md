# Asset Governance Certification Diagnostics

Diagnostics are health-only copied metadata.

Diagnostics expose lifecycle state, counts, limit usage, runtime limits, certification posture, requirement posture, review posture, provider posture, dependency posture, Bootstrap posture, documentation posture, integration posture, validation posture, bounded validation failures, and the last self-check result.

Diagnostics never expose services, Instances, functions, threads, userdata, runtime handles, asset handles, loaded assets, callbacks, listeners, execution adapters, client state, remotes, Workspace references, or mutable internal tables.

Provider and posture keys:

- provider sampler: `assetGovernanceCertificationRuntime`
- provider posture: `assetGovernanceCertificationRuntime`
- certification posture key: `assetGovernanceCertificationPosture`

Phase 62 hardens diagnostics so static runtime metadata from `Types` is copied before exposure. `dependencyPosture`, `bootstrapPosture`, `documentationPosture`, and `runtimeLimits` must not return mutable references to the implementation tables.

Diagnostics remain health-only. They do not certify live execution, authorize asset use, create listeners, dispatch signals, attach callbacks, store services, or expose adapters.
