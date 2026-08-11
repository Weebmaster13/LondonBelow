# Composition Graph

Every composition definition is a directed rooted graph that behaves as a tree
for Phase 183. Validation enforces exactly one root, a matching `rootNodeId`, no
duplicate nodes, no missing parents, no parent on the root, no cycles, no
unreachable nodes, and bounded depth.

Child ordering is deterministic. Siblings sort by explicit `order`, then by
stable `nodeId`. This makes compilation output repeatable for identical input
and protects future diff phases from order drift.

Graph failures reject before definition registration, and rejection evidence is
recorded without mutating existing definitions.
