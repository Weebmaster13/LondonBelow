# Runtime Shutdown Plan Runtime

Shutdown plans are schemas, not shutdown commands.

Shutdown plans may reference only registered nodes, registered dependency records, and registered ordering records. Shutdown plans do not stop runtimes, call shutdown APIs, mutate live systems, clear live service state, or execute cleanup logic.
