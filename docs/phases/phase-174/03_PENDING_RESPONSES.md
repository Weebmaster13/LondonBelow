# Pending Responses

Pending responses are server-authoritative metadata records. They are not client UI and are not network contracts.

`InteractionValidator` requires the response kind to match the session `expectedResponse`. Invalid responses leave the interaction in its waiting state. Valid responses transition the session through received, validated, applied, and completed states, then remove the pending queue entry.

Ordering is deterministic by priority and request insertion order.
