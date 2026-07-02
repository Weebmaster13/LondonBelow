# Security Rate-Limit Runtime

Rate limits are policies, not automatic throttles.

This runtime records future rate-limit policy schemas only. It does not throttle requests, mutate queues, inspect clients, punish players, or enforce networking behavior.

Rate-limit schemas require `rateLimitId`, `ownerSystem`, optional `schemaType = SecurityRateLimitSchema`, safe metadata, safe context, and safe tags.

Rate limits are constraints for future systems, not automatic throttles. They cannot inspect players, monitor clients, mutate queues, punish players, or enforce networking behavior from this runtime.
