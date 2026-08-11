# Diagnostics And Snapshots

Diagnostics expose provider identity, runtime identity, capability identity,
platform, definitions, compositions, resolved plans, bindings, ownership,
revisions, evidence, metrics, profiler records, budgets, governance,
certification posture, counters, failures, and `robloxVisualCompositionPosture`.

Snapshots use provider `robloxVisualCompositionRuntime` and root
`robloxVisualCompositionSnapshot`.

Diagnostics and snapshots are deep-copy isolated. Mutation attempts against
returned tables do not alter runtime state.
