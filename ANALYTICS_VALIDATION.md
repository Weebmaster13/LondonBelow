# Analytics Validation

Analytics validation rejects malformed records, unsupported schema types, duplicate ids across one global analytics schema namespace, unsafe payloads, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and deep payloads.

It also rejects:

- Telemetry sending fields
- External analytics fields
- Player tracking fields
- Moderation fields
- Profiling execution fields
- HTTP service fields
- DataStore fields
- Messaging service fields
- Remote and client fields
- UI, Workspace, and gameplay fields
- Chapter, story, dialogue, and cutscene fields

Validation never collects analytics, sends telemetry, tracks players, reports externally, moderates, profiles, calls HTTP, writes DataStores, publishes messages, creates remotes, trusts clients, mutates Workspace, executes gameplay, or adds Chapter content.

## Boundary Rules

- Event records must use `AnalyticsEventSchema` when a schema type is present.
- Metric records must use `AnalyticsMetricSchema` when a schema type is present.
- Aggregation records must use `AnalyticsAggregationSchema` when a schema type is present.
- Consent records must use `AnalyticsConsentSchema` when a schema type is present.
- Retention records must use `AnalyticsRetentionSchema` when a schema type is present.
- Report records must use `AnalyticsReportSchema` when a schema type is present.
- Event, metric, aggregation, consent, retention, and report ids may not overlap.

Validation diagnostics are sanitized. They must never expose raw Roblox Instances, functions, threads, userdata, cyclic references, or oversized payloads.
