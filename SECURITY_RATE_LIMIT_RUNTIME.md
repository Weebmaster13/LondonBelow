# Security Rate-Limit Runtime

Rate limits are policies, not automatic throttles.

This runtime records future rate-limit policy schemas only. It does not throttle requests, mutate queues, inspect clients, punish players, or enforce networking behavior.

Rate-limit schemas require `rateLimitId`, `ownerSystem`, optional `schemaType = SecurityRateLimitSchema`, safe metadata, safe context, and safe tags.
