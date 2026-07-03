# Dependency Runtime

Phase 44 defines the London Engine State Machine Runtime Foundation. This is server-authoritative schema infrastructure only. It describes future state machine structure so other governed systems can refer to stable ids and relationships, but it never runs those structures.

## Hard Boundary

Definitions are records, not executable machines. States are descriptions, not live states. Transitions are descriptions, not executed transitions. Guards are descriptions or references, not evaluated guards. Inputs are descriptions, not consumed inputs. Outputs are descriptions, not emitted outputs. Groups are structure only, not execution batches. Dependencies are metadata, not blockers. Outcomes are possible future results, not computed results. Audits are review summaries, not enforcement.

The runtime does not own state machine execution, state transition execution, live state mutation, gameplay state mutation, guard evaluation, input consumption, output emission, animation state execution, gameplay state execution, AI state execution, Monster AI state execution, Narrative state execution, Presentation state execution, trigger execution, condition evaluation, rule evaluation, event dispatch, Scheduler execution, Lifecycle execution, Event Graph execution, Runtime Graph execution, Rule Engine execution, Trigger Runtime execution, Condition Runtime execution, runtime orchestration, scripting, callbacks, listeners, Save execution, Workspace mutation, remotes, RemoteEvent creation, RemoteFunction creation, client authority, DataStore reads or writes, HttpService, MessagingService, analytics collection, telemetry sending, Chapter content, final story, final dialogue, or cutscenes.

## Runtime Shape

The implementation lives in `src/ServerScriptService/StateMachine/Core`. `StateMachineCoordinator` is the lifecycle facade registered by Bootstrap. Category facade modules expose narrow `register` methods. `StateMachineState` owns bounded source-of-truth maps and a single global namespace across definitions, states, transitions, guards, inputs, outputs, groups, dependencies, outcomes, and audits. `StateMachineValidation` rejects malformed schemas, unsupported schema types and kinds, invalid references, self dependencies, direct dependency cycles, unsafe metadata, unsafe context, unsafe tags, forbidden markers, cyclic tables, Roblox Instances, functions, threads, userdata, oversized strings, oversized node counts, and deep payloads before mutation. `StateMachineSerialization` deep-copies public outputs and sanitizes diagnostic payloads.

## Validation Coverage

Definition records validate domain, reference lists, state references, transition references, guard references, input references, output references, group references, dependency references, outcome references, and per-machine list limits. State records validate machine ownership and supported state kinds. Transition records validate machine ownership, source and target states, supported transition kinds, and reject same-source/target transitions unless marked as future/no-op schemas. Guard, input, output, group, dependency, outcome, and audit records each validate ids, supported kinds, references, limits, and forbidden payloads.

## Diagnostics And Snapshots

Diagnostics are health-only. They expose lifecycle state, health, validation status, category counts, per-category limit usage, runtime limits, serialization posture, isolation proof, integrity posture, recent sanitized validation failures, and the last self-check result. Diagnostics do not monitor live state machines, expose current state truth, expose handles, mutate schema state, or become execution.

Snapshots are isolated deep copies of schema state only. They contain counts, schema records, integrity posture, validation failures, and no-execution posture. They never contain live state machine handles, live state, current-state truth, transition handles, guard evaluator handles, input or output execution handles, listener references, callbacks, remotes, Workspace references, or execution adapters.

## Self-Check Certification

`StateMachineSelfChecks` is pre-start certification. It proves malformed records reject, duplicate ids reject globally, unsupported types and kinds reject, invalid references reject, forbidden fields reject in keys and string values, serialization rejects unsafe runtime values, histories are bounded, every category limit rejects safely, snapshots are isolated, diagnostics are read-only copies, shutdown clears state and namespace data, and no execution surface exists.

## Future Work Rules

Future systems may reference State Machine schema ids. They must not treat definitions, states, transitions, guards, inputs, outputs, groups, dependencies, outcomes, or audits as commands. Any future state machine execution must be a separate governed runtime with its own contract, validation, diagnostics, snapshots, self-checks, security review, and production audit.
