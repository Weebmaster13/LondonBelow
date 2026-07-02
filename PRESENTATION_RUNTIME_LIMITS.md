# Presentation Runtime Limits

Phase 22 uses explicit limits:

- Requests: `260`
- Queue records: `180`
- Approvals per request: `12`
- Channels per request: `12`
- Routing records: `260`
- Validation failures: `180`
- Snapshot history: `80`
- Payload depth: `8`
- Payload nodes: `260`
- Payload string length: `512`
- Priority: `0` to `100`
- Default expiration: `30` seconds

Bounded histories trim old records.
