# Cognition Runtime Limits

Living Cognition is bounded by design. The runtime should never grow unbounded while a server is alive.

## State Limits

- Cognitive entities: `MaxEntities`.
- Observations per entity: `MaxObservationsPerEntity`.
- Evidence records per entity: `MaxEvidencePerEntity`.
- Hypotheses per entity: `MaxHypothesesPerEntity`.
- Thoughts per entity: `MaxThoughtsPerEntity`.
- Beliefs per entity: `MaxBeliefsPerEntity`.
- Trace history: `MaxTraceHistory`.
- Validation failures: `MaxValidationFailures`.
- Diagnostics history: `MaxDiagnosticsHistory`.

## Payload Limits

- Maximum payload depth: `MaxPayloadDepth`.
- Maximum payload node count: `MaxPayloadNodes`.
- Maximum payload string length: `MaxPayloadStringLength`.

## Cleanup Rules

The coordinator schedules periodic cleanup while running. Cleanup removes expired evidence and stale archived or near-zero-confidence hypotheses and thoughts. Shutdown clears registry state, runtime buckets, traces, validation failures, and diagnostics history.

## Conservative Defaults

Unknown or invalid data must be rejected or remain unknown. The runtime must not invent certainty, goals, commands, movement, pacing, scares, attacks, or presentation from incomplete cognition data.