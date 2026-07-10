# Asset Governance Certification Inspection Diagnostics

Diagnostics are health-only and expose copied metadata only.

Required posture keys:

- `inspectionPosture`
- `observationPosture`
- `findingPosture`
- `auditPosture`
- `providerPosture`
- `snapshotPosture`
- `integrationReadinessPosture`
- `runtimeCompatibilityPosture`
- `providerCompatibilityPosture`
- `snapshotCompatibilityPosture`
- `bootstrapCompatibilityPosture`
- `governanceCompatibilityPosture`
- `documentationCompatibilityPosture`
- `inspectionCoveragePosture`
- `documentationPosture`
- `bootstrapPosture`
- `governancePosture`
- `noAuthorityPosture`
- `noRepairPosture`
- `noExecutionPosture`
- `noMutationPosture`

Diagnostics also expose counts, limit usage, runtime limits, recent sanitized validation failures, and `lastSelfCheckResult`.

Diagnostics never expose services, Instances, functions, threads, userdata, callbacks, listeners, runtime handles, asset handles, loaded assets, execution adapters, repair handles, authorization handles, remotes, live subsystem references, or mutable internal tables.

`integrationReadinessPosture` is a copied array of static compatibility declarations. It is not a live subsystem handle and cannot mutate upstream runtime state.
