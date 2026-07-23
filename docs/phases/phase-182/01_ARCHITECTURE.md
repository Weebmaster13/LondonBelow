# Phase 182 Architecture

Phase 182 adds `RuntimeRobloxRenderingSession` and `RobloxRenderingSessionCoordinator` under `src/ServerScriptService/Presentation/Core`.

Runtime identity:

- Provider: `robloxRenderingSessionRuntime`
- Capability: `robloxRenderingSessionRuntimeCapability`
- Platform: `Roblox`
- Authority: Server
- Bootstrap order: immediately after `RobloxRenderingCoordinator`

The runtime owns session metadata only. It prepares the handoff from platform-agnostic rendering execution to future Roblox visual composition and concrete renderer implementations.
