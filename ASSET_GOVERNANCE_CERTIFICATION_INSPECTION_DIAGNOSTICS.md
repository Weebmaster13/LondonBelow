# Asset Governance Certification Inspection Diagnostics

Diagnostics are health-only and expose copied metadata only.

Posture keys:

- `inspectionPosture`
- `observationPosture`
- `findingPosture`
- `auditPosture`
- `providerPosture`
- `snapshotPosture`
- `runtimeCompatibilityPosture`
- `inspectionCoveragePosture`
- `documentationPosture`
- `bootstrapPosture`
- `governancePosture`

Diagnostics include counts, limit usage, runtime limits, recent sanitized validation failures, the last self-check result, copied certified runtime coverage, copied Bootstrap posture, copied documentation posture, and explicit no-authority posture.

Diagnostics do not expose services, Instances, functions, threads, userdata, callbacks, listeners, execution adapters, repair handles, authorization handles, live subsystem references, or mutable internal tables.
