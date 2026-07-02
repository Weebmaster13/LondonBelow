# Presentation Request Runtime

`PresentationRequestRuntime` stores normalized presentation request schemas.

Every request contains:

- `presentationId`
- `requester`
- `sourceSystem`
- `presentationType`
- `priority`
- `createdAt`
- `expiresAt`
- `approvals`
- `channels`
- `metadata`
- `context`
- `reason`

Requests are deep-copied, bounded, and rejected before storage if unsafe.
