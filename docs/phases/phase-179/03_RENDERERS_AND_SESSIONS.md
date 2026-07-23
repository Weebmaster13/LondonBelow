# Renderers And Sessions

`RendererRuntimeRegistry` records renderer metadata only. Renderer registrations declare supported rendering kinds, versions, capacity, priority, status, registration ordinal, and runtime metadata.

`RenderingSessionRegistry` creates server-owned rendering sessions from validated request metadata. Sessions preserve rendering request, execution session, presentation session, rendering kind, synchronization policy, lifecycle state, assignment state, queue ordinal, and runtime priority.
