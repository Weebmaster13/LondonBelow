# Acknowledgements And Synchronization

`RenderingAcknowledgementProducer` creates immutable acknowledgement metadata for renderer-side outcomes.

Acknowledgements must match the rendering session, rendering request, and assigned renderer. Duplicate ids, unknown sessions, invalid kinds, and ownership mismatches reject safely.

`RenderingSynchronizationRuntime` evaluates synchronization metadata only and never advances Presentation Runtime Execution directly.
