# Subscriptions

Subscriptions declare how consumers listen to event types through metadata.

Fields:

- `subscriptionId`
- `consumerId`
- `eventType`
- `priority`
- `deliveryMode`
- `version`

Delivery modes are `Ordered`, `Deferred`, and `Once`.

Resolution is deterministic by event type, descending priority, version, and registration order. Phase 167 does not dispatch event payloads; the Runtime Event Bus remains the event authority.
