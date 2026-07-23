# Architecture

Rendering Contracts define what should be rendered. Rendering Runtime owns runtime state. Future rendering execution owns execution scheduling. Future concrete renderers own Roblox visualization.

Provider identity is `presentationRenderingRuntime`; runtime identity is `presentationRenderingRuntime`; capability identity is `presentationRenderingRuntimeCapability`.

The runtime remains server-authoritative, deterministic, metadata-only, and isolated from rendering behavior.
