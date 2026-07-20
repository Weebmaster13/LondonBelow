# Queue Model

Presentation commands are queued with:
- priority
- revision
- expiration
- source runtime
- immutable command payload

Priority order:
Critical, Interaction, Inspection, Context, Ambient.

Tie-breaking is deterministic by priority, revision, then command id. Expired commands are removed deterministically.
