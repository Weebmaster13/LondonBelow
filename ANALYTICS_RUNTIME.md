# Analytics Runtime

Phase 31 defines the Analytics Boundary Foundation for London Engine.

This runtime is server-authoritative schema infrastructure for future analytics events, metric definitions, aggregation schemas, consent/eligibility schemas, retention policies, and report schemas.

It records analytics structure only. It does not collect analytics or send telemetry.

## Owns

- Analytics event schemas
- Metric definition schemas
- Aggregation schemas
- Consent and eligibility schemas
- Retention policy schemas
- Report schemas
- Validation
- Serialization
- Diagnostics
- Snapshots
- Deterministic self-checks
- Shutdown cleanup

## Does Not Own

- Analytics collection
- Telemetry sending
- Player tracking
- External reporting
- Moderation
- Profiling execution
- HTTP calls
- DataStore writes
- MessagingService
- Remotes
- Client authority
- UI
- Workspace mutation
- Gameplay execution
- Chapter content

Any future live analytics pipeline must be a separate governed runtime with explicit consent, retention, privacy, and transport review.
