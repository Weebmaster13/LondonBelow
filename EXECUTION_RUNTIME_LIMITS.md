# Execution Runtime Limits

Phase 20 uses explicit limits to keep long-running servers stable.

## Limits

- Requests: `240`
- Queue: `160`
- Audit records: `320`
- Validation failures: `160`
- Snapshot history: `80`
- Schedules: `160`
- Approvals per request: `12`
- Dependencies per request: `24`
- Payload depth: `8`
- Payload nodes: `260`
- Payload string length: `512`
- Priority: `0` to `100`
- Default expiration: `30` seconds

When bounded histories exceed limits, old records are removed. Queue overflow rejects safely.
