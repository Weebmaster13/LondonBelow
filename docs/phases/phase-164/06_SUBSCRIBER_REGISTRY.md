# Subscriber Registry

`EventSubscriberRegistry.lua` owns runtime-focused subscriptions.

Subscriptions declare `subscriptionId`, `subscriberId`, `runtimeId`, event type filters, handler, failure policy, and metadata.

The Event Bus foundation does not create gameplay-object subscriptions. Subscriber handlers receive immutable event snapshots.
