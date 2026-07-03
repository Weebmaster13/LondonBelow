# Runtime Node Runtime

Runtime nodes are identity records, not live runtime instances.

Nodes describe runtime name, layer, phase, status, capabilities, requirements, dependency ids, group ids, metadata, context, and tags. They do not expose runtime objects, service handles, module references, callbacks, remotes, Framework internals, or execution adapters.

Certified nodes reject module references, service references, execution adapters, runtime objects, Framework references, callbacks, and lifecycle execution markers.
