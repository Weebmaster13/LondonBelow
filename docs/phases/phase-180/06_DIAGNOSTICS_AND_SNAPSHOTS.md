# Diagnostics And Snapshots

Diagnostics expose provider identity, runtime identity, scheduler state, execution sessions, queue state, renderer workloads, acknowledgements, synchronization records, recovery metadata, evidence, metrics, profiler metadata, budgets, Governance, certification posture, and lowerCamelCase `renderingExecutionPosture`.

Snapshots use provider `presentationRenderingExecution` and expose `presentationRenderingExecutionSnapshot`. Snapshot payloads are deep copies and cannot mutate runtime state.

Diagnostics and snapshots are health and inspection surfaces only. They are not certification authority and do not execute renderer work.
