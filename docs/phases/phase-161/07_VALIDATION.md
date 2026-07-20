# Validation

Save validation covers:

- duplicate objective IDs
- duplicate checkpoint IDs
- schema version
- migration version
- corrupted objective state
- invalid checkpoint state
- missing identifiers
- unknown fields
- unsafe runtime references
- client, remote, DataStore, networking, analytics, and telemetry markers

Invalid saves reject before serialization or deserialization publishes usable output.
