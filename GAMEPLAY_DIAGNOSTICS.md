# Gameplay Diagnostics

`GameplayCoordinator.inspect()` exposes the Phase 13 runtime snapshot.

Diagnostics include:

- registered gameplay definitions
- active object states
- door state counts
- inventory item counts
- key counts
- objective progress
- puzzle graph status
- puzzle hint counts
- failed validation counters
- recent gameplay events
- memory counts
- health state

Diagnostics are server-side. They are for development, QA, simulation, and future admin tooling. They do not grant client authority.
