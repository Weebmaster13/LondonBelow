# Condition Runtime Limits

The runtime enforces explicit limits for conditions, categories, expressions, operands, operators, groups, dependencies, states, outcomes, audits, validation failures, snapshots, payload depth, payload nodes, string length, tags, expression operands, group conditions, condition references, and audit findings.

These limits exist to keep schema infrastructure bounded and predictable as London Engine grows. They are not gameplay balance values and do not imply live execution behavior.

Future evaluators must define their own limits rather than borrowing these schema limits as runtime execution policy.

## Production Hardening

Hitting a limit rejects safely before mutation. It does not evict source-of-truth schemas, evaluate conditions, execute expressions, trigger gameplay, call Rule Engine, call Event Graph, call Scheduler, create remotes, or mutate Workspace.
