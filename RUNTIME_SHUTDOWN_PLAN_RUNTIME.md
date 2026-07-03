# Runtime Shutdown Plan Runtime

Shutdown plans are schemas, not shutdown commands.

Shutdown plans may reference only registered nodes, registered dependency records, and registered ordering records. Shutdown plans do not stop runtimes, call shutdown APIs, mutate live systems, clear live service state, or execute cleanup logic.

Certified shutdown plans reject oversized node/dependency/ordering lists, shutdown execution payloads, live system mutation payloads, Framework mutation payloads, runtime API payloads, and service references.
