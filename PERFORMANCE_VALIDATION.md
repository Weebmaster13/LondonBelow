# Performance Validation

Performance validation rejects malformed records, unsupported schema types, duplicate ids across one global performance schema namespace, unsafe payloads, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and deep payloads.

It also rejects:

- profiling execution fields;
- optimization execution fields;
- throttling execution fields;
- analytics and telemetry fields;
- memory, network, and render mutation fields;
- client and remote fields;
- Workspace and gameplay fields;
- Chapter, story, dialogue, and cutscene fields.

Validation never profiles live systems, optimizes code, throttles runtime behavior, collects analytics, sends telemetry, mutates memory/network/render state, monitors clients, creates remotes, mutates Workspace, executes gameplay, or adds Chapter content.

## Safe Failure

Rejected schemas do not create partial state, fallback reports, temporary thresholds, runtime mutations, or client authority.
