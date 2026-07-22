# Interaction Requests

An interaction request must include:

- `interactionId`
- `executionId`
- `conversationId`
- `currentNodeId`
- `expectedResponse`

Optional fields include `timeoutDuration`, `priority`, and metadata.

Duplicate interaction ids reject before mutation. Invalid or missing ownership fields reject before mutation. Accepted requests transition to `WaitingForResponse` and enter the pending choice queue.
