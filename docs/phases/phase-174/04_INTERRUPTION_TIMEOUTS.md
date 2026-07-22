# Interruptions And Timeouts

`DialogueInterruptionManager` records interruption and resume metadata for dialogue executions.

`InteractionTimeoutManager` expires known interactions, removes them from the pending queue, records timeout evidence, and closes the session.

`NestedConversationManager` records bounded parent-child execution metadata and return targets. It does not execute child dialogue itself.
