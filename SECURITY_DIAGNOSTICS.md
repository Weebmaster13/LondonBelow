# Security Diagnostics

Security diagnostics expose:

- initialized;
- started;
- lifecycle state;
- trust policy count;
- authority rule count;
- exploit signal count;
- client rejection count;
- remote safety count;
- rate-limit count;
- audit count;
- validation failure count;
- snapshot count;
- runtime limits;
- per-category limit usage;
- serialization posture;
- snapshot isolation proof;
- no-execution posture;
- recent sanitized validation failures;
- last self-check result;
- health state.

Diagnostics are health-only. They are not live anti-cheat, exploit detection, client monitoring, analytics collection, telemetry, moderation, punishment, or enforcement.

## Hardened Diagnostics

Diagnostics expose lifecycle state, health, validation posture, per-category counts and limits, serialization posture, snapshot isolation proof, diagnostics isolation proof, no-execution posture, recent sanitized validation failures, and the last self-check result.

Diagnostics must not expose live player data, export telemetry, generate moderation evidence, contain remotes, contain service references, preserve raw unsafe payload references, become player-facing UI, become analytics, or become anti-cheat.
