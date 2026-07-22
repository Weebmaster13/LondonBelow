# Conversation Instances

Conversation instances are bounded runtime-memory records.

Instance fields:

- conversationId
- dialogueId
- participants
- currentNodeId
- currentVariables
- state
- startedTime
- updatedTime

Phase 172 records structural conversation state only. It does not implement the operational execution engine for node traversal, player choice input, UI, audio, saves, or persistence.
