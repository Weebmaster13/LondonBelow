# Asset Execution Adapter Registry Self-Checks

Self-checks are deterministic and executable before runtime start.

Coverage includes provider consistency, runtime consistency, registry consistency, snapshot consistency, diagnostics consistency, Bootstrap consistency, Governance consistency, documentation consistency, schema validation, enum validation, duplicate adapter ids, duplicate registration ids, duplicate registry ids, duplicate registry names, duplicate ownership, ownership validation, registration ownership, boundary validation, audit validation, failed-validation no mutation, serializer contamination rejection, diagnostics isolation, snapshot isolation, runtime-limit enforcement, deep-copy isolation, shutdown cleanup, namespace reset, regression protection, lowerCamelCase posture keys, and banned runtime surface absence.

Self-checks do not execute adapters or create gameplay behavior.

## Phase 104 Production Hardening

Self-checks now expand coverage for schema exactness, field exactness, field ordering, schema insertion/deletion/replacement/rotation/reversal, unsupported schema count keys, enum deletion, identity drift, ordering drift, metadata drift, evidence drift, tag drift, serializer contamination, runtime-limit drift, lowerCamelCase posture validation, failed-validation no mutation, shutdown cleanup, namespace reset, previous phase regression protection, and banned runtime surface absence.
