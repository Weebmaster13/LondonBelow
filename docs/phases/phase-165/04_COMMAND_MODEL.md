# Command Model

Accepted commands are immutable intent records containing command identity, command type, schema version, requester, owner runtime, priority, payload, correlation id, causation id, idempotency key, sequence, and metadata.

Submitting a command does not imply success. Execution success is recorded only after the authoritative handler returns a successful normalized result.

Part II hardening makes the accepted command envelope explicit. Each envelope carries creation, admission, scheduled, execution, and completion timestamps; execution state; cancellation state; result, diagnostics, and evidence references; and a lifecycle history. Raw payloads do not travel through the Command Bus after admission.
