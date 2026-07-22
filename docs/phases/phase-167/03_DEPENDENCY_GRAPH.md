# Dependency Graph

Consumer dependencies form a directed graph.

Validation guarantees:

- dependencies exist;
- consumers cannot depend on missing consumers;
- cycles reject;
- initialization order is deterministic;
- shutdown order is the reverse dependency order.

The graph is exposed through diagnostics and snapshots as immutable inspection data. It is not a scheduler, not a workflow engine, and not gameplay orchestration.
