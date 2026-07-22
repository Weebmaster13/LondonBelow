# Workflow Definitions

Every workflow definition contains:

- `workflowId`
- `version`
- `ownerRuntime`
- `category`
- `entryState`
- `states`
- `transitions`
- `timeouts`
- `retryPolicy`
- `cancellationPolicy`
- `completionPolicy`

Definitions are immutable after registration. Unknown fields, missing fields, duplicate workflow ids, unsupported categories, unsupported transition sources, invalid states, invalid entry states, unsafe payload fields, and oversized payloads reject before mutation.
