# Lifecycle State Runtime

Lifecycle states are records, not live runtime states.

State records describe a runtime node id, lifecycle state, phase, status, reason, metadata, context, and tags. They never hold live runtime objects, Framework references, service handles, callbacks, or execution adapters.

## Hardening Rules

Lifecycle state records must reject unsupported lifecycle state values, unsafe metadata/context/tags, live runtime objects, live lifecycle state handles, Framework references, service handles, callbacks, execution adapters, remotes, Workspace references, persistence markers, and Chapter/story/dialogue/cutscene fields. They describe a runtime node; they never start, stop, initialize, mutate, or recover it.
