# Runtime Ordering Runtime

Ordering records are plan metadata, not startup or shutdown execution.

Ordering records require registered source and target nodes. Self-ordering rejects. Directly contradictory ordering pairs reject when represented directly. Ordering records do not start systems, stop systems, call Framework, or mutate lifecycle state.
