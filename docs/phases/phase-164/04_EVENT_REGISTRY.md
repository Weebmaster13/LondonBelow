# Event Registry

`EventRegistry.lua` registers immutable typed event definitions.

Definitions include `eventType`, `schemaVersion`, `ownerRuntime`, `defaultPriority`, `deliveryPolicy`, `replayPolicy`, `payloadValidator`, `allowedPublishers`, and metadata/no-subscriber policy fields.

Duplicate event types, malformed definitions, invalid priorities, invalid replay policies, and missing payload validators reject before mutation.
