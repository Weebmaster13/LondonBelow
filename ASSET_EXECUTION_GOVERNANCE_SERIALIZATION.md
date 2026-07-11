# Asset Execution Governance Serialization

Serialization provides deep copies for state, diagnostics, and snapshots. It rejects functions, threads, userdata, cycles, instance-shaped tables, unsafe markers, oversized strings, excessive depth, and excessive node counts.

Serialization is metadata-only. It never stores live subsystem handles and never creates asset loading, runtime routing, authorization, or execution surfaces.
