# Asset Usage Plan Runtime

Phase 46 defines the London Engine Asset Usage Plan Runtime Foundation. This runtime is server-authoritative schema infrastructure only. It describes future asset usage intent: where an asset is expected to be used, why it is expected there, which context applies, and which safety, performance, dependency, budget, and accessibility constraints are declared.

## Hard Boundary

This runtime is metadata-only. It never loads, preloads, resolves, streams, spawns, applies, mutates, executes, sends, saves, or creates gameplay. It does not call content services, insert services, marketplace services, storage services, network remotes, HTTP, messaging, analytics, telemetry, or client APIs. It does not create Instances, UI, VFX, particles, models, sounds, animations, maps, rooms, dialogue, cutscenes, or Chapter content.

## Schema Categories

Usage plan definitions describe the asset id, intended consumer, usage domain, usage kind, priority, and child schema references. Context records describe chapter-agnostic or runtime-allowed context metadata. Constraint records describe safety/performance/accessibility/content rules. Dependencies describe relationships between plans but never execute ordering. Budgets describe declared limits only. Accessibility records describe accommodations only. Audits are review summaries only.

## Validation Guarantees

Validation rejects nil or non-table schemas, invalid ids, unsupported schema types, unsupported kinds, missing plan references, duplicate ids in the global namespace, self-dependencies, direct dependency cycles, unsafe metadata, unsafe context, unsafe tags, functions, threads, userdata, Roblox Instances, instance-shaped tables, callbacks, listeners, remotes, runtime handles, asset handles, loaded asset handles, module references, execution adapters, oversized strings, oversized payloads, deep payloads, and forbidden loading/execution/storage/client/content markers. Validation happens before mutation, and failed validation records bounded sanitized diagnostics without changing source-of-truth state.

## Diagnostics And Snapshots

Diagnostics are health-only and expose lifecycle state, counts, limit usage, validation failures, dependency posture, safety posture, and no-execution posture. Snapshots are isolated deep copies of schema data only. Public outputs never expose mutable internal state, runtime handles, service references, client state, storage references, or asset handles.

## Runtime Limits

The runtime enforces bounded counts for usage plans, contexts, constraints, dependencies, budgets, accessibility records, audits, validation failures, snapshots, payload depth, payload nodes, string length, tags, audit findings, and plan children. Hitting a limit rejects safely before mutation and never evicts valid schema data.

## Future Runtime Ownership

Future execution or application systems must be separate governed runtimes with their own contracts, validation, diagnostics, snapshots, self-checks, security review, and production audit. This runtime may be referenced by those systems, but it must never become the application or loading layer.
