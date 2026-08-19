# Roblox GUI Rendering Runtime

Phase 186 client-owned presentation runtime. `RobloxGuiRenderingRuntime.render` accepts only Phase 185 schema `1.0.0` contracts. It validates again at the client boundary, stages a complete tree while detached, commits through a root swap, rolls back failed staging or commit work, and exposes local diagnostics.

Phase 187 production-hardens the runtime with exact-field validation, single-root ownership, integer monotonic revisions, bounded metadata, stale-revision rejection, and runtime-owned tree integrity verification.

Phase 188 adds a real local interaction and accessibility execution layer. `RobloxGuiInteractionRuntime.registerAction` binds presentation-only callbacks to validated `actionId` metadata. Roblox `GuiButton.Activated` provides one mouse, touch, keyboard, and gamepad path. The runtime enforces disabled controls, deterministic selection order, focus restoration after revision replacement, local focus announcements, bounded diagnostics, and connection cleanup.

Phase 189 production-hardens interaction with generation-fenced callbacks, same-action reentrancy rejection, exact connection-ledger balance, modal focus scopes, initial focus, immutable accessibility preferences, polite/assertive live regions, reconciliation rate budgets, and local PlayerGui remount recovery. These remain presentation-only mechanisms and never establish gameplay truth.

The runtime never decides gameplay truth, fetches contracts, creates remotes, persists state, or sends analytics/telemetry. Studio certification remains blocked until authoritative structured Studio evidence is imported.
