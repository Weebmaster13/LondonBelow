# Failure Injection

The self-check suite injects malformed definitions, duplicate definitions,
unsafe callback payloads, unknown fields, invalid composition kinds, missing
roots, multiple roots, duplicate nodes, missing parents, circular hierarchy,
invalid node kinds, invalid semantic roles, invalid semantic/node pairings,
invalid layout anchors, impossible constraints, invalid responsive variants,
invalid theme references, invalid typography references, invalid asset
references, invalid accessibility metadata, semantic-only asset intent,
duplicate composition IDs, duplicate session bindings, stale revisions, illegal
lifecycle transitions, reset, and shutdown.

Each injected failure must reject without partial mutation and leave unrelated
state inspectable.
