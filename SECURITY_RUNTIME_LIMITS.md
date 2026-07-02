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
