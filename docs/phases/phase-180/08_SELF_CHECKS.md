# Self Checks

Phase 180 self-checks cover:

- runtime identity
- execution session creation and duplicate rejection
- queue admission and deterministic scheduling order
- lifecycle transition legality
- renderer workload metadata
- acknowledgement validation, duplicate rejection, unsupported kind rejection, and renderer ownership mismatch rejection
- synchronization records
- suspension and resumption
- cancellation and expiration
- recovery metadata
- diagnostics isolation
- snapshot isolation
- evidence, metrics, profiler, budgets, Governance, and certification posture
- reset and shutdown behavior
- prohibited runtime surface absence through automation wrapper checks

Automation entry points:

- `npm run london:phase180:selfcheck`
- `npm run london:presentation-rendering-execution`
- `npm run london:presentation-rendering-execution:validate`
