# Request Protocol

Requests require `requestId` and `interactionId`. Optional fields include `targetId`, `playerId`, `requestKind`, and metadata.

The runtime rejects duplicate request ids per player window and never trusts client-provided success, distance, target state, or completion.
