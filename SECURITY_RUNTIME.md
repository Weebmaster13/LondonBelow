# Security / Anti-Exploit Boundary Runtime

Phase 34 defines the server-authoritative Security / Anti-Exploit Boundary Foundation for London Engine.

This runtime records schemas for future trust policies, authority rules, exploit signal definitions, client rejection categories, remote safety contracts, rate-limit policies, validation violation categories, and audit records.

It is a security policy schema runtime only. It does not detect exploits, punish players, monitor clients, create remotes, read or write DataStores, collect analytics, send telemetry, mutate Workspace, execute gameplay, or add Chapter content.

## Ownership

Security Boundary owns:

- trust policy schemas;
- authority rule schemas;
- exploit signal definition schemas;
- client rejection category schemas;
- remote safety contract schemas;
- rate-limit policy schemas;
- audit record schemas;
- validation;
- serialization;
- diagnostics;
- snapshots;
- deterministic self-checks;
- shutdown cleanup.

Future live anti-cheat, moderation, enforcement, telemetry, client monitoring, and remote security systems must be separate governed systems.

## Certification Rules

- Trust policies are policy data, not live enforcement.
- Authority rules are schemas, not authority grants.
- Exploit signals are definitions, not detection events.
- Client rejections are categories, not punishments.
- Remote safety contracts are schemas, not `RemoteEvent` or `RemoteFunction` instances.
- Rate limits are policies, not automatic throttles.
- Audit records are inert schemas, not moderation logs.
- Diagnostics are health-only, not client monitoring.
- Snapshots are isolated schema data, not evidence packets.
- Self-checks are pre-start certification only, not live security tools.

Any future system consuming this runtime must treat schemas as constraints, not commands.
