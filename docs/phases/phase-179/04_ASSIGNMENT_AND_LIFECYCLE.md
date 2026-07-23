# Assignment And Lifecycle

`RendererAssignmentManager` selects compatible renderers deterministically by compatibility, availability, priority, current load, registration ordinal, and stable renderer id.

`RenderingLifecycleManager` is the sole lifecycle authority. Illegal transitions reject before mutation.

Assignment state remains separate from lifecycle state.
