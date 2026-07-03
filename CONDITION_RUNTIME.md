# Condition Runtime Foundation

Phase 42 adds the server-authoritative Condition Runtime Foundation for London Engine.

Condition Runtime is schema infrastructure only. Conditions are records, expressions are descriptions, operators are metadata, operands are schema values, groups are logical structure only, dependencies are metadata, states are schema descriptions, outcomes are possible future results, and audits are review summaries.

No evaluation occurs. No execution occurs. Future condition evaluation belongs in a separate governed runtime with its own contract, validation, diagnostics, and explicit approval from Governance.

The runtime owns validation, serialization, diagnostics, snapshots, deterministic self-checks, and shutdown cleanup for condition schemas. It rejects unsupported schema types, unsupported domains, unsupported operators, unsafe payloads, invalid references, self dependencies, direct dependency cycles, oversize payloads, unsafe runtime values, and fields that imply execution, client authority, remotes, services, analytics, telemetry, Workspace mutation, Chapter content, story, dialogue, or cutscenes.

Bootstrap registers `ConditionCoordinator` as a foundation service. Diagnostics are exposed through `ConditionCoordinator.inspect`, and snapshots are exposed through the `conditionRuntime` provider.
