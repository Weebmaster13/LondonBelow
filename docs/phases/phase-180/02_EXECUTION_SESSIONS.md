# Execution Sessions

Rendering execution sessions are created by `RenderingExecutionSessionRegistry`.

Each session records:

- `renderingExecutionSessionId`
- `renderingSessionId`
- `renderingRequestId`
- `rendererId`
- `schedulerState`
- `executionState`
- `queueOrdinal`
- `executionOrdinal`
- `runtimePriority`
- `assignmentPriority`
- `runtimeMetadata`

Sessions reject nil payloads, unsupported fields, missing ids, duplicate ids, and limit overflow before mutation. Mutable runtime APIs copy state before exposure, so diagnostics and snapshots cannot be used to alter registered sessions.
