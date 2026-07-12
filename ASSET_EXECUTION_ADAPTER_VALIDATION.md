# Asset Execution Adapter Validation

Validation is schema-first and always occurs before mutation.

Validation covers exact schema fields, required fields, id format, enum values, provider identity, snapshot provider identity, duplicate ids, duplicate adapter names, capability ownership, compatibility ownership, boundary ownership, audit ownership, ordered child reference arrays, evidence arrays, tag arrays, metadata safety, and bounded limits.

Validation rejects nil and non-table schemas, unsupported fields, invalid ids, duplicate ids, duplicate adapter names, unsupported enum values, missing adapter references, cross-adapter audit references, unordered child references, unsafe metadata, executable references, cyclic payloads, metatables, oversized payloads, instance-shaped payloads, callbacks, listeners, handlers, runtime handles, registry handles, execution handles, and future executable adapter surfaces.

Failed validation records a bounded diagnostic failure copy and performs no state mutation.
## Phase 102 Production Hardening

Validation now independently rejects schema insertion, deletion, replacement, rotation, reversal, duplicate schema keys, unsupported schema count keys, enum insertion, enum deletion, identity aliases, casing drift, whitespace drift, punctuation drift, provider drift, snapshot drift, coordinator drift, Bootstrap drift, Governance snapshot provider drift, documentation drift, runtime-limit drift, unsupported fields, unsafe metadata, unsafe evidence, unsafe tags, duplicate ids, duplicate adapter names, missing ownership references, cross-parent audit references, and failed-validation mutation.

The canonical fields remain exactly those declared by `AssetExecutionAdapterTypes`; docs must not introduce aliases for adapter records, capabilities, compatibility records, boundaries, or audits.
