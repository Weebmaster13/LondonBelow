# Phase 181 Architecture

Phase 181 adds `RuntimeRobloxRenderingCapability` and `RobloxRenderingCoordinator` under `src/ServerScriptService/Presentation/Core`.

Runtime identity:

- Provider: `robloxRenderingRuntime`
- Capability: `robloxRenderingCapability`
- Platform: `Roblox`
- Authority: Server
- Bootstrap order: immediately after `PresentationRenderingExecutionCoordinator`

The runtime owns Roblox renderer capability metadata only. Future phases may bind this capability to renderer sessions and concrete Roblox UI/rendering execution.
