# Asset Execution Adapter Contract Validation

Adapter-contract validation is part of the existing Asset Execution Runtime validation pass.

Validation requires exact declaration count, exact field names, exact field ordering, exact declaration ordering, exact provider identities, exact snapshot provider, coordinator identity, diagnostics identity, Governance provider, Bootstrap dependency, contract enums, status enums, lifecycle boundary enums, authority boundary enums, operation boundary enums, required flags, copied evidence, copied tags, copied metadata, dense ordered arrays, and duplicate-id rejection.

Validation rejects sparse arrays, dictionary-shaped arrays, unsupported fields, unsupported order tables, enum drift, punctuation drift, casing drift, whitespace drift, identity aliases, nested unsafe payloads, metadata drift, evidence drift, and tag drift.

Failed adapter-contract validation is non-mutating. It cannot alter registered execution runtimes, requests, boundaries, audits, global ids, runtime counts, lifecycle state, runtime limits, integration declarations, adapter-readiness declarations, adapter-contract declarations, or order tables.

## Phase 98 Hardening

Phase 98 expands deterministic validation around adapter-contract declarations. It independently verifies the exact declaration count, declaration order, declaration identities, field count, field order, required flags, provider names, snapshot provider, diagnostics provider, coordinator name, runtime name, Governance provider, Bootstrap dependency, compatibility ids, adapter contract ids, declaration ids, evidence arrays, tag arrays, metadata keys, lifecycle boundaries, serialization boundaries, validation boundaries, authority boundaries, and operation boundaries.

Validation rejects deletion, insertion, replacement, reversal, rotation, duplication, truncation, expansion, dictionary-shaped declarations, sparse declarations, non-array declarations, mixed declaration types, invalid ids, identity aliases, casing drift, whitespace drift, punctuation drift, prefix drift, suffix drift, nested unsafe payloads, and serializer contamination.
