# Synchronization

`PresentationSynchronizationRuntime` evaluates lifecycle and acknowledgement state and returns synchronization metadata.

It does not advance Dialogue Execution, mutate Workflow Runtime, publish events, or call remotes.

Synchronization records are bounded and immutable through inspection.
