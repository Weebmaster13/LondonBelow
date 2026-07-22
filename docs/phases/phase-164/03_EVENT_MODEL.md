# Event Model

Each event is admitted as an immutable envelope containing:

- `eventId`
- `eventType`
- `schemaVersion`
- `sourceRuntime`
- `issuedTimestamp`
- `priority`
- `payload`
- `correlationId`
- `causationId`
- `sequence`
- `metadata`

Server-owned sequence values provide deterministic ordering. Event IDs must be unique within bounded runtime history.
