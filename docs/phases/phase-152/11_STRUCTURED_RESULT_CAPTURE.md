# Structured Result Capture

Phase 152 adds `RunnerResultSchema.mjs`, `ExecutionEvidenceValidator.mjs`, and `ExecutionEvidenceImporter.mjs`.

Imported evidence must be JSON, inside `automation/local-state/runtime-execution`, and must match:

- schema version;
- runner ID;
- session ID;
- phase;
- repository commit;
- assertion status vocabulary;
- certification boundary.

Certification mutation is rejected. Path traversal is rejected. Missing, malformed, stale, mismatched, or checksum-invalid evidence is rejected.
