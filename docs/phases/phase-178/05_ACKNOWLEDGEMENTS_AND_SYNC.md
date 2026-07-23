# Acknowledgements And Synchronization

`RendererAcknowledgementRegistry` records immutable acknowledgement metadata for rendering requests.

Acknowledgements must reference an existing rendering request and match execution/presentation ownership. Duplicate acknowledgement ids, invalid kinds, unknown requests, and ownership mismatches reject before mutation.

`RenderingSynchronizationManager` evaluates synchronization policy satisfaction and returns metadata only. It does not resume Presentation Runtime Execution or communicate with clients.
