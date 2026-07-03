# Schedule Dependency Runtime

Dependencies are ordering metadata, not blockers.

Dependency records describe source and target plan ids plus dependency kind. They do not block live work, wake work, process queues, or execute orchestration.

Dependencies reject missing plan references, self-dependencies, direct two-plan cycles, unsafe payloads, and runtime orchestration markers.
