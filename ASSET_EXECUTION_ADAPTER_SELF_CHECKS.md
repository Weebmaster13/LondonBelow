# Asset Execution Adapter Self-Checks

Phase 101 adds deterministic executable self-checks for the Asset Execution Adapter Runtime.

Coverage includes provider consistency, runtime identity, snapshot provider identity, diagnostics provider identity, coordinator identity, Bootstrap ordering, Governance registration, schema validation, enum validation, duplicate rejection, duplicate adapter-name rejection, invalid ids, capability ownership, compatibility ownership, boundary ownership, audit ownership, adapter child references, failed-validation no mutation, diagnostics isolation, snapshot isolation, deep-copy isolation, runtime-limit enforcement, shutdown cleanup, namespace reset, previous phase regression protection, and banned runtime surface absence.

The self-checks do not execute adapter behavior. They prove the runtime remains copied metadata only.
## Phase 102 Production Hardening

Self-checks now cover provider/runtime/coordinator/diagnostics/snapshot/Bootstrap/Governance/documentation consistency, exact schema count, exact field count, field ordering, schema insertion/deletion/replacement/rotation/reversal rejection, enum insertion/deletion rejection, ownership validation, duplicate id rejection, duplicate adapter name rejection, identity alias rejection, metadata/evidence/tag contamination rejection, serializer contamination rejection, diagnostics isolation, snapshot isolation, runtime-limit drift rejection, lifecycle cleanup, namespace reset, failed-validation no mutation, deep-copy isolation, regression protection, lowerCamelCase posture keys, and banned runtime surface absence.

The self-check suite remains deterministic and must pass before Phase 102 can be marked production certified.
