# Runtime Lifecycle Validation

Validation rejects malformed ids, duplicate ids across one global namespace, unsupported schema types, unsupported lifecycle states, unsupported transition/policy/guard/event/failure/recovery/compatibility kinds, invalid references, identical non-future transitions, self-contradictory policies, unsafe metadata/context/tags, Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized payloads, and deep payloads.

Forbidden lifecycle, service, Framework, Runtime Graph, dependency injection, module loading, require-call, execution, remote, client, persistence, analytics, telemetry, Chapter, story, dialogue, cutscene, service reference, adapter reference, handler reference, callback, runtime object, and Workspace path fields reject anywhere in nested payloads.

## Production Hardening

Validation now treats Runtime Lifecycle as a boundary runtime. Forbidden values are rejected in payload keys, payload values, metadata, context, tags, and nested tables before state mutation. This includes retry, restore, disable, pause, resume, unload, reload, lifecycle mutation, live EventBus emission, gameplay signal, Runtime Graph call, Security call, Save call, Presentation call, service lookup, live runtime object, live lifecycle state, live service handle, live error object, secret stack trace, enforcement, remediation, moderation, punishment, migration execution, adapter loading, runtime patch, and execute markers.

The validator never performs live checks. It only proves schema shape, supported enums, safe serialization, bounded references, and category ownership.
