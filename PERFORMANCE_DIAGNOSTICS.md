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
