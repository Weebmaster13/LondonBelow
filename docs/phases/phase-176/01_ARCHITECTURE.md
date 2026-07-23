# Phase 176 Architecture

`PresentationRuntimeCoordinator` registers immediately after `DialoguePresentationCoordinator`.

Dialogue defines presentation intent. Presentation Runtime manages presentation state. Rendering remains outside this phase.

The runtime uses `presentationRuntimeCapability` as capability identity and `presentationRuntime` as provider identity.
