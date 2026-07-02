# Security Runtime Limits

Security Boundary Runtime is bounded by design.

- Trust policy schemas are capped.
- Authority rule schemas are capped.
- Exploit signal schemas are capped.
- Client rejection schemas are capped.
- Remote safety contracts are capped.
- Rate-limit policies are capped.
- Audit records are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, string length, and tag count are capped.

All ids share one global security schema namespace. Hitting a limit is a safe rejection, never live anti-cheat, enforcement, punishment, monitoring, remote creation, analytics, telemetry, or source-of-truth eviction.

## Certified Limits

- `MaxTrustPolicies` bounds trust policy schemas.
- `MaxAuthorityRules` bounds authority rule schemas.
- `MaxExploitSignals` bounds exploit signal definitions.
- `MaxClientRejections` bounds client rejection categories.
- `MaxRemoteSafetyContracts` bounds remote safety contracts.
- `MaxRateLimits` bounds rate-limit policies.
- `MaxAudits` bounds audit records.
- `MaxValidationFailures` bounds sanitized validation history.
- `MaxSnapshotHistory` bounds snapshot history.
- `MaxPayloadDepth`, `MaxPayloadNodes`, `MaxPayloadStringLength`, and `MaxTags` bound schema shape.

Category limits reject safely before mutation. Hitting a limit must not evict source-of-truth schemas, trigger enforcement, create fallback policy, monitor clients, or punish players.
