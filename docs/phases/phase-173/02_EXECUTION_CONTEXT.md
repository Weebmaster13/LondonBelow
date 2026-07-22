# Execution Context

Execution contexts contain:

- executionId
- conversationId
- dialogueId
- currentNodeId
- previousNodeId
- variables
- participants
- workflowReference
- executionState
- runtimeMetadata

Contexts are copied on inspection and snapshots. They are mutable only through `RuntimeDialogueExecution`.
