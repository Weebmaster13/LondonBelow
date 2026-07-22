# Query Bus Runtime

`RuntimeQueryBus.lua` owns query submission, schema validation, requester authorization, deterministic queueing, routing, execution, immutable query results, diagnostics, snapshots, and shutdown cleanup.

Every accepted query receives an immutable envelope with query identity, query type, schema version, requester, correlation and causation ids, owner runtime, namespace, priority, consistency model, cache policy, metadata, payload, and lifecycle timeline.
