# Asset Execution Adapter Registration Workflow Self-Checks

Self-checks are deterministic executable checks for Phase 105 certification.

Coverage includes provider consistency, runtime consistency, workflow consistency, snapshot consistency, diagnostics consistency, Bootstrap consistency, Governance consistency, documentation consistency, schema validation, enum validation, workflow ownership, duplicate rejection, transition validation, decision validation, audit validation, identity drift, ordering drift, metadata drift, evidence drift, tag drift, serializer contamination, diagnostics isolation, snapshot isolation, runtime-limit enforcement, failed-validation no mutation, deep-copy isolation, shutdown cleanup, namespace reset, previous phase regression protection, lowerCamelCase posture validation, and banned runtime surface absence.

## Phase 106 Production Hardening

Self-checks now cover schema exactness, field exactness, field ordering, schema insertion, schema deletion, schema replacement, schema rotation, schema reversal, unsupported schema keys, enum insertion and deletion, provider aliases, snapshot aliases, coordinator identity drift, documentation drift, runtime-limit drift, signal drift, coordinator API drift, duplicate stage ownership, invalid transition ordering, cross-workflow references, metadata-key contamination, evidence contamination, and tag contamination.
## Phase 107 Processing Readiness Self-Checks

Self-check coverage expands to include:

- provider and snapshot provider consistency
- exact processing-readiness field order
- exact processing-readiness declaration order
- declaration count matching `MaxProcessingReadinessDeclarations`
- readiness kind and readiness status validation
- input, output, dependency, precondition, postcondition, and boundary enum validation
- declaration evidence, tag, and metadata contamination rejection
- failed validation no mutation
- diagnostics and snapshot isolation for declaration metadata
- lowerCamelCase processing posture keys
- future processor absence posture
- registry-write separation posture
- shutdown cleanup
- banned runtime surface absence

Self-checks do not create processing behavior.
