# Command Model

Accepted commands are immutable intent records containing command identity, command type, schema version, requester, owner runtime, priority, payload, correlation id, causation id, idempotency key, sequence, and metadata.

Submitting a command does not imply success. Execution success is recorded only after the authoritative handler returns a successful normalized result.
