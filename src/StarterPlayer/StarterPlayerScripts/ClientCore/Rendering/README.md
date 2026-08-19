# Roblox GUI Rendering Runtime

Phase 186 client-owned presentation runtime. `RobloxGuiRenderingRuntime.render` accepts only Phase 185 schema `1.0.0` contracts. It validates again at the client boundary, stages a complete tree while detached, commits through a root swap, rolls back failed staging or commit work, and exposes local diagnostics.

Phase 187 production-hardens the runtime with exact-field validation, single-root ownership, integer monotonic revisions, bounded metadata, stale-revision rejection, and runtime-owned tree integrity verification.

The runtime never decides gameplay truth, fetches contracts, creates remotes, persists state, or sends analytics/telemetry. Studio certification remains blocked until authoritative structured Studio evidence is imported.
