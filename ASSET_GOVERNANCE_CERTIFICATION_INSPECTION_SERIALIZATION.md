# Asset Governance Certification Inspection Serialization

Serialization performs bounded deep-copy and diagnostic-copy operations for copied inspection metadata.

Safe payloads may contain strings, numbers, booleans, nil values, and plain tables within configured limits. Serialization rejects cycles, oversized strings, deep payloads, oversized node counts, functions, threads, userdata, Instance-shaped tables, callbacks, listeners, runtime handles, asset handles, loaded asset handles, module references, execution adapters, repair markers, authorization markers, mutation markers, orchestration markers, scheduling markers, networking markers, persistence markers, and live subsystem markers.

Diagnostic copies sanitize rejected payloads. They never preserve callbacks, listeners, handles, executable values, or mutable runtime references.

Phase 70 readiness metadata uses the same serialization boundary as inspection records. Readiness declarations may contain copied plain metadata only, and unsafe compatibility metadata is rejected before it can affect runtime state.

Phase 71 decision-readiness metadata uses the same serialization boundary. Decision-readiness declarations may contain copied plain metadata only. Serialization rejects decision engines, decision logic, decision trees, approval logic, execution markers, repair markers, authorization markers, mutation markers, callbacks, listeners, services, runtime handles, mutable references, networking markers, persistence markers, and live subsystem references.
