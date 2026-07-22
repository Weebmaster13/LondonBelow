# Persistence Runtime

`PersistenceRuntime` coordinates provider registration, provider resolution, request execution, response validation, retry classification, diagnostics, snapshots, and evidence.

The runtime stores serialized payloads. It does not interpret objective state, checkpoint state, gameplay state, migration schemas, or Save Runtime schemas.
