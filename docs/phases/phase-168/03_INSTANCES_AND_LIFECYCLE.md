# Instances And Lifecycle

Workflow definitions are immutable templates. Runtime execution creates workflow instances.

Each instance records:

- `instanceId`
- `workflowId`
- `correlationId`
- `causationId`
- current state
- immutable variable snapshots
- start time
- completion time
- state history

Lifecycle:

```text
Created -> Registered -> Validated -> Scheduled -> Running -> Waiting -> Completed -> Archived
```

`Cancelled` and `Failed` are explicit terminal states. Terminal instances reject later mutation.
