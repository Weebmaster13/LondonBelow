# Asset Execution Adapter Registration Workflow Validation

Validation is schema-first and validation-before-mutation.

Validation verifies exact schema names, exact schema count, field counts, field ordering, enum values, workflow ids, stage ids, transition ids, decision ids, audit ids, duplicate ids, duplicate workflow names, duplicate stage ordering, ownership references, cross-workflow references, missing parents, missing stages, missing transitions, runtime identity, provider identity, snapshot identity, coordinator identity, workflow limits, metadata, evidence, and tags.

Validation rejects nil and non-table schemas, unsupported fields, unsupported metadata, unsupported evidence, unsupported tags, callbacks, listeners, functions, threads, userdata, Instances, metatables, runtime handles, workflow handles, registry handles, adapter implementations, activation handles, execution handles, dispatcher handles, scheduler handles, router handles, orchestrator handles, asset-operation references, network handles, analytics, telemetry, gameplay references, Presentation references, Save references, Chapter references, cyclic payloads, and oversized payloads.

Failed validation performs zero mutation.

## Phase 106 Production Hardening

Validation now explicitly protects schema insertion, deletion, replacement, rotation, reversal, alias schemas, unsupported schema keys, enum insertion, enum deletion, provider drift, snapshot drift, coordinator drift, Bootstrap drift, Governance provider drift, documentation drift, runtime-limit drift, duplicate stage ownership, invalid transition ordering, missing decision references, cross-workflow references, unsafe metadata keys, unsafe evidence, unsafe tags, and failed-validation no mutation.
