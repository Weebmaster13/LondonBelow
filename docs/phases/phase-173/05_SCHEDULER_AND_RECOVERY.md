# Scheduler And Recovery

`DialogueScheduler` owns deterministic execution queue metadata, suspension records, resumption records, and scheduler operation evidence.

The scheduler does not own gameplay timing or background task execution.

Recovery restores the current execution context, node, variables, execution state, participant metadata, and workflow reference. It does not reconstruct gameplay, write saves, or touch persistence.
