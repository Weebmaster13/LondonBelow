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

## Category Rules

- Budget schemas require `budgetId`, `ownerSystem`, and an optional matching budget schema type.
- Category schemas require `categoryId`, `ownerSystem`, and an optional matching category schema type.
- Threshold schemas require `thresholdId`, `ownerSystem`, and an optional matching threshold schema type.
- Report schemas require `reportId`, `ownerSystem`, and an optional matching report schema type.

Every category rejects unsafe metadata, unsafe context, unsafe tags, unsupported schema types, and forbidden execution or mutation fields. Duplicate ids reject across the entire performance namespace so a report cannot shadow a threshold, a threshold cannot shadow a category, and a category cannot shadow a budget.

Budgets are policy data, not measurements. Thresholds are warnings, not throttles. Reports are schemas, not telemetry exports. Validation protects that boundary before state changes.
