# Governance

Phase 180 adds a Governance contract for Presentation Rendering Runtime Execution and Renderer Session Management.

Governance records:

- server authority
- provider `presentationRenderingExecution`
- runtime id `presentationRenderingExecutionRuntime`
- snapshot provider `presentationRenderingExecution`
- Bootstrap dependency on `PresentationRenderingRuntimeCoordinator`
- ownership of execution metadata only
- explicit prohibited surface boundaries

Governance is passive metadata. It does not certify runtime execution and does not implement renderer behavior.
