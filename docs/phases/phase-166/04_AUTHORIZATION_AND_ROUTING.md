# Authorization and Routing

Before queue admission, the Query Bus validates requester identity, query permissions, namespace ownership, payload schema, schema version, owner runtime, and handler availability.

Routing depends only on query type, namespace, schema version, owner runtime, and the registered handler. No runtime heuristics are used.
