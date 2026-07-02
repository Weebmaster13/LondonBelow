# Analytics Event Runtime

Analytics event schemas describe future event shapes as data.

Each event must include:

- `eventId`
- `ownerSystem`
- optional `schemaType = "AnalyticsEventSchema"`
- safe `metadata`
- safe `context`
- safe `tags`

Registering an event schema does not observe players, collect events, send telemetry, or write reports.
