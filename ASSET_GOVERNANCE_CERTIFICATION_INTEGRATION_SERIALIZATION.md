# Asset Governance Certification Integration Serialization

Serialization supports bounded metadata payloads only.

Serializable values may contain primitive values and bounded tables. Payload validation rejects cycles, functions, threads, userdata, Instance-shaped tables, runtime handles, callbacks, listeners, module references, execution adapters, oversized strings, excessive depth, excessive node counts, and forbidden runtime markers.

Diagnostics use sanitized copies for validation failures. Snapshots use isolated deep copies. No runtime handle, service handle, callback, listener, live subsystem reference, or mutable internal table is exposed.

Serialization is not persistence, networking, execution authorization, repair, orchestration, scheduling, asset loading, gameplay, Presentation, Save, or Chapter content.

Phase 66 self-checks prove unsafe metadata rejection across integration, chain, review, and audit schemas.
