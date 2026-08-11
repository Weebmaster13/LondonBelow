# Composition Model

A visual composition definition is reusable authored structure. It has a stable
`compositionId`, semantic `compositionKind`, version, root node, supported
presentation kinds, theme reference, nodes, and metadata.

A visual composition instance is runtime-specific metadata. It binds one
definition to a Roblox rendering session, rendering execution session,
rendering session, presentation session, renderer, owner, revision, lifecycle,
state variants, and metadata.

Definitions are immutable after registration. Instances carry runtime state so
authored composition data does not become polluted by revision and lifecycle
state.
