# Validation Pipeline

Publication validates:

1. Envelope shape.
2. Event type resolution.
3. Schema version.
4. Payload.
5. Publisher resolution.
6. Publisher permission.
7. Priority.
8. Replay policy metadata.
9. Queue admission.

Failures return normalized result records and do not mutate downstream state.
