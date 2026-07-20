# Migration Runtime

`SaveMigrationRuntime` provides a deterministic migration pipeline.

Phase 161 supports schema version `1` and migration version `1`. The current migration is a no-op for already-current records.

Missing schema version, missing migration version, unsupported schema version, and unsupported migration version reject.
