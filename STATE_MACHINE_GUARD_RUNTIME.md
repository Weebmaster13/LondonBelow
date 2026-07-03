# Guard Schema Runtime

Phase 44 adds the London Engine State Machine Runtime Foundation as server-authoritative schema infrastructure. It exists to describe future machine definitions, states, transitions, guards, inputs, outputs, groups, dependencies, outcomes, and audits without running any of them.

## Responsibility Boundary

This runtime owns records, validation, serialization, diagnostics, snapshots, deterministic self-checks, and shutdown cleanup. Definitions are records. States are descriptions, not live state. Transitions are descriptions, not executed transitions. Guards are references or descriptions, not evaluated logic. Inputs are descriptions, not consumed signals. Outputs are descriptions, not emitted effects. Groups are structure only. Dependencies are metadata. Outcomes are possible future results. Audits are review summaries.

It does not own state machine execution, live transitions, guard evaluation, input consumption, output emission, animation state behavior, gameplay state behavior, AI behavior, Monster AI, Narrative, Presentation, triggers, conditions, rules, event dispatch, Scheduler behavior, Lifecycle behavior, runtime orchestration, Save behavior, Workspace mutation, remotes, client authority, DataStore, HttpService, MessagingService, analytics, telemetry, Chapter content, final story, final dialogue, or cutscenes.

## Runtime Shape

The implementation lives in `src/ServerScriptService/StateMachine/Core`. `StateMachineCoordinator` is the public lifecycle facade. Category modules expose focused `register` functions that delegate into the coordinator. `StateMachineState` owns internal immutable-style registries and global id uniqueness. `StateMachineValidation` rejects malformed schemas, unsafe payloads, unsupported kinds, invalid references, duplicate ids, forbidden fields, deep payloads, oversized strings, cyclic data, Roblox Instances, functions, threads, and userdata. `StateMachineSerialization` deep-copies public outputs so callers cannot mutate internal state.

## Integration

Bootstrap registers `StateMachineCoordinator` with the Framework lifecycle. Governance registers the State Machine Runtime Foundation contract so future Codex work can verify the boundary before adding related systems. Diagnostics are exposed through `StateMachineCoordinator.inspect`; snapshots are exposed through `stateMachineRuntime`.

## Future Use

Future systems may reference State Machine schema ids when they need a governed description of allowed states or transitions. They must not treat these schemas as commands. If London Engine ever needs execution, that work must be built as a separate governed runtime with its own contracts, validation, diagnostics, safety rules, and review.

## Certification Notes

The self-check suite proves malformed and duplicate records reject, invalid references reject, limits are enforced, forbidden fields reject, serialization rejects unsafe runtime values, histories remain bounded, snapshots are isolated, diagnostics are read-only copies, shutdown clears state, and no execution posture is preserved.
