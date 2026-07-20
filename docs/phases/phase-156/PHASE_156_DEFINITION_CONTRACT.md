# Definition Contract

Definitions are validated through `InteractionValidation.schema`. Unsupported types, invalid ids, unsafe payloads, forbidden ownership fields, invalid cooldowns, invalid locks, and unsupported statuses reject before state changes.

The runtime supports future handler contracts but does not own final gameplay mutation.
