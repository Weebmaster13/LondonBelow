# Acknowledgements And Synchronization

`RenderingExecutionAcknowledgements` consumes acknowledgement metadata for execution sessions. It validates acknowledgement id, execution session id, renderer ownership, supported acknowledgement kind, duplicate ids, and acknowledgement limits before recording.

Supported acknowledgement kinds are `Accepted`, `Assigned`, `Started`, `Completed`, `Cancelled`, `Failed`, and `Expired`.

`RenderingExecutionSynchronization` resolves immutable synchronization records from scheduler state, execution state, latest acknowledgement metadata, and terminal status. Synchronization records are metadata only and do not trigger rendering, networking, Workspace mutation, gameplay, dialogue, or AI.
