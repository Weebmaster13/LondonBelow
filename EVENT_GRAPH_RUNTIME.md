# Event Graph Runtime

Phase 40 defines the London Engine Event Graph Runtime Foundation. This runtime is event graph schema infrastructure only: it records event nodes, channels, edges, sources, sinks, subscription schemas, propagation policies, priorities, filters, payload contracts, ordering records, and audit records as server-authoritative data.

It is not live EventBus execution. It is not event dispatch, signal firing, remote event creation, subscription execution, listener execution, callback execution, payload delivery, event routing, event propagation, queue processing, filter execution, priority execution, gameplay event execution, orchestration execution, or Chapter content.

## Ownership

The runtime owns validation, serialization, diagnostics, snapshots, deterministic self-checks, bounded schema state, global Event Graph id namespace, and shutdown cleanup. All schemas are copied into state after validation. Public diagnostics and snapshots are isolated copies.

## Boundary Rules

- Event nodes are records, not live events.
- Channels are schema channels, not EventBus channels.
- Edges are relationships, not propagation.
- Sources are origin schemas, not publishers.
- Sinks are recipient schemas, not listeners.
- Subscriptions are relationship schemas, not live subscriptions.
- Propagation records are policies, not propagation execution.
- Priorities are policy values, not dispatch order.
- Filters are schema constraints, not live filtering.
- Payload contracts describe shape, not payload delivery.
- Ordering records are metadata, not event sequencing execution.
- Audits are review summaries, not enforcement.

## Validation Posture

Validation rejects missing ids, malformed ids, duplicate ids across the global Event Graph namespace, unsupported schema types, unsupported domains and kinds, invalid references, self relationships, direct ordering contradictions, unsafe metadata, unsafe context, unsafe tags, live EventBus fields, publish/subscribe/listener/callback fields, RemoteEvent/RemoteFunction fields, client communication fields, execution fields, Workspace fields, DataStore/HttpService/MessagingService fields, analytics/telemetry fields, Chapter/story/dialogue/cutscene fields, Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized payloads, and overly deep payloads.

## Runtime Limits

Runtime limits bound event nodes, channels, edges, sources, sinks, subscriptions, propagations, priorities, filters, payload contracts, orderings, audits, validation failures, snapshot history, payload depth, payload node count, payload string length, tags, reference lists, payload field lists, and audit findings. Hitting a limit rejects safely before mutation and never dispatches or processes events.

## Diagnostics And Snapshots

Diagnostics are health-only. They expose lifecycle state, counts, limit usage, validation state, recent sanitized failures, integrity posture, no-execution posture, and last self-check result. Snapshots contain schema state and counts only. Neither diagnostics nor snapshots expose live EventBus references, listener references, callbacks, remotes, service handles, module references, Workspace references, dispatch handles, payload handles, queue handles, or execution adapters.

## Future Integration

Future EventBus integration, event dispatch, listener execution, callback execution, remote communication, and event processing must be separate governed systems. Consumers must treat Event Graph schemas as constraints and planning data, not commands.
