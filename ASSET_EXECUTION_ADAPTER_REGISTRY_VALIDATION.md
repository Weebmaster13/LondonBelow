# Asset Execution Adapter Registry Validation

Validation is schema-first and always occurs before mutation.

Validation covers exact schema names, exact field counts, field ordering, enum values, provider identity, runtime identity, registry identity, snapshot identity, coordinator identity, registration ownership, duplicate adapter ids, duplicate registration ids, duplicate adapter names, duplicate registry names, duplicate ownership, missing ownership, cross-parent references, runtime limits, metadata safety, evidence safety, tag safety, serializer safety, and deep-copy safety.

Validation rejects nil and non-table schemas, unsupported fields, invalid ids, duplicate ids, unsupported enum values, missing references, callbacks, listeners, functions, threads, userdata, instance-shaped payloads, metatables, cyclic payloads, registry handles, runtime handles, adapter implementations, execution handles, asset operation handles, scheduler handles, dispatcher handles, router handles, gameplay references, Presentation references, Save references, Chapter references, analytics markers, telemetry markers, network markers, persistence markers, unsupported metadata, unsupported evidence, and unsupported tags.

Failed validation records a bounded diagnostic failure copy and performs no state mutation.

## Phase 104 Production Hardening

Validation now independently rejects schema insertion, deletion, replacement, rotation, reversal, alias schemas, unsupported schema keys, unsupported schema count keys, enum insertion, enum deletion, identity aliases, ordering drift, runtime-limit drift, unsupported metadata, unsupported evidence, unsupported tags, duplicate adapter ids, duplicate registry ids, duplicate registration ids, duplicate compatibility ids, duplicate boundary ids, duplicate registry names, duplicate ownership, missing ownership, cross-parent references, invalid ordering, and failed-validation mutation.

Registration remains metadata. Registration is not activation, execution, or authorization.
