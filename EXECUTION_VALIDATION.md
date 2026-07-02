# Execution Validation

`ExecutionValidation` protects the bridge from unsafe or premature execution requests.

## Rejections

Validation rejects:

- duplicate execution ids
- missing execution ids
- missing approvals
- missing dependencies
- expired execution requests
- unsupported execution types
- client payloads
- Workspace references
- Roblox Instances
- functions, threads, userdata
- cyclic tables
- oversized strings
- oversized payloads
- deep payloads
- execution-like payloads
- movement, damage, animation, UI, lighting, audio, remote, Chapter, story, dialogue, cutscene, Monster AI, and horror pacing fields

## Supported Types

Phase 20 supports dry-run schema types only:

- `GameplayStatePlan`
- `PhysicalRuntimePlan`
- `PresentationRuntimePlan`
- `SystemCoordinationPlan`

These are plans, not execution commands.
