# Roblox GUI Rendering Runtime

Phase 186 client-owned presentation runtime. `RobloxGuiRenderingRuntime.render` accepts only Phase 185 schema `1.0.0` contracts. It validates again at the client boundary, stages a complete tree while detached, commits through a root swap, rolls back failed staging or commit work, and exposes local diagnostics.

The runtime never decides gameplay truth, fetches contracts, creates remotes, persists state, or sends analytics/telemetry.
