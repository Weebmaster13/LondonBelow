# Runtime Lifecycle Validation

Validation rejects malformed ids, duplicate ids across one global namespace, unsupported schema types, unsupported lifecycle states, unsupported transition/policy/guard/event/failure/recovery/compatibility kinds, invalid references, identical non-future transitions, self-contradictory policies, unsafe metadata/context/tags, Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized payloads, and deep payloads.

Forbidden lifecycle, service, Framework, Runtime Graph, dependency injection, module loading, require-call, execution, remote, client, persistence, analytics, telemetry, Chapter, story, dialogue, cutscene, service reference, adapter reference, handler reference, callback, runtime object, and Workspace path fields reject anywhere in nested payloads.
