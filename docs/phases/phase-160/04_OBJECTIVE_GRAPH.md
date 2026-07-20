# Objective Graph

Phase 160 defines a small deterministic Chapter 0 graph:

1. Inspect Mum's Note
2. Restore Power
3. Open Front Door
4. Leave Home

Each objective unlocks the next through explicit prerequisites. The graph supports AND and OR prerequisite modes, but Chapter 0 uses the linear AND path for replay consistency.

Cycle detection and missing reference validation run before the graph is registered.
