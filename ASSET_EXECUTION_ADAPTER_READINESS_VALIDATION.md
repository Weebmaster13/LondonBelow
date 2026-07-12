# Asset Execution Adapter Readiness Validation

Adapter-readiness validation is part of the existing Asset Execution Runtime validation pass.

Validation requires:

- exact 38-declaration count
- exact field names and field order
- exact declaration order tables
- valid `readinessKind` and `readinessStatus`
- valid `adapterKind`
- valid `adapterAuthorityKind`
- valid `adapterBoundaryKind`
- valid `assetOperationBoundaryKind`
- valid `lifecycleBoundaryKind`
- exact provider, snapshot provider, coordinator, diagnostics provider, Bootstrap dependency, and Governance snapshot provider
- exact execution runtime identity fields
- exact future adapter absence fields
- exact copied evidence, tags, and metadata
- dense ordered arrays only
- no duplicate declaration ids
- no unsafe payloads

Validation rejects deletion, insertion, replacement, reversal, rotation, sparse arrays, dictionary-shaped arrays, unsupported fields, unsupported order tables, missing order tables, enum drift, casing drift, identity aliases, evidence drift, tag drift, metadata drift, live adapter contamination, asset-operation contamination, gameplay contamination, Presentation contamination, Save contamination, Chapter contamination, and unsafe nested values.

Failed adapter-readiness validation is non-mutating. It cannot alter registered execution runtimes, requests, boundaries, audits, global ids, runtime counts, lifecycle state, runtime limits, Phase 93 integration declarations, Phase 95 adapter-readiness declarations, or order tables.

