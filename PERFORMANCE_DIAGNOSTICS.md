# Performance Diagnostics

Performance diagnostics expose:

- initialized;
- started;
- lifecycle state;
- budget count;
- category count;
- threshold count;
- report count;
- validation failure count;
- snapshot count;
- runtime limits;
- serialization posture;
- snapshot isolation proof;
- no-execution posture;
- last self-check result;
- health state.

Diagnostics are read-only copies and safe for Framework health checks. They do not sample live performance, collect analytics, send telemetry, monitor clients, or apply optimization behavior.

## Health-Only Diagnostics

Performance diagnostics are not live profiling. They expose runtime health, schema counts, limit usage, validation posture, snapshot isolation proof, no-execution posture, and recent sanitized validation failures.

Diagnostics must not be used as telemetry exports, analytics reports, profiling samples, optimization triggers, throttling signals, or client monitoring records. Future systems that need those capabilities must define separate governed runtimes.
