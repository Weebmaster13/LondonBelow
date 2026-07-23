# Renderer Capabilities

`RendererCapabilityRegistry` records renderer capability declarations only.

Capability declarations include renderer capability id, renderer type, provider, version, supported rendering kinds, supported contract versions, supported descriptor versions, supported synchronization policies, supported reference categories, priority, capacity metadata, ordinal, status, and runtime metadata.

`RendererCompatibilityValidator` produces deterministic compatibility metadata. It never assigns renderers and never executes rendering.
