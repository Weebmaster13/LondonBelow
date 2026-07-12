# Asset Execution Adapter Contract Validation

Adapter-contract validation is part of the existing Asset Execution Runtime validation pass.

Validation requires exact declaration count, exact field names, exact field ordering, exact declaration ordering, exact provider identities, exact snapshot provider, coordinator identity, diagnostics identity, Governance provider, Bootstrap dependency, contract enums, status enums, lifecycle boundary enums, authority boundary enums, operation boundary enums, required flags, copied evidence, copied tags, copied metadata, dense ordered arrays, and duplicate-id rejection.

Validation rejects sparse arrays, dictionary-shaped arrays, unsupported fields, unsupported order tables, enum drift, punctuation drift, casing drift, whitespace drift, identity aliases, nested unsafe payloads, metadata drift, evidence drift, and tag drift.

Failed adapter-contract validation is non-mutating. It cannot alter registered execution runtimes, requests, boundaries, audits, global ids, runtime counts, lifecycle state, runtime limits, integration declarations, adapter-readiness declarations, adapter-contract declarations, or order tables.

