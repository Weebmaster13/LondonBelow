# Asset Execution Governance Serialization

Serialization provides deep copies for state, diagnostics, and snapshots. It rejects functions, threads, userdata, cycles, instance-shaped tables, unsafe markers, oversized strings, excessive depth, and excessive node counts.

Serialization is metadata-only. Phase 81 integration-readiness declarations use the same safe-copy and unsafe-marker rules as governance records. Phase 82 proves nested unsafe metadata rejection and returned-copy isolation for declarations, runtime limits, diagnostics, and snapshots. Serialization never stores live subsystem handles and never creates asset loading, runtime routing, authorization, or execution surfaces.
