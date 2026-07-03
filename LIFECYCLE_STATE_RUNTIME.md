# Lifecycle State Runtime

Lifecycle states are records, not live runtime states.

State records describe a runtime node id, lifecycle state, phase, status, reason, metadata, context, and tags. They never hold live runtime objects, Framework references, service handles, callbacks, or execution adapters.
