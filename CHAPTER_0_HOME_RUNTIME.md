# Chapter 0 Home Runtime

Phase 109 adds the minimum playable Chapter 0 Home vertical slice. Phase 110 hardens
that same runtime without adding Chapter 1, final art, final audio, save
persistence, or new networking. Phase 111 adds the first bounded atmospheric
feedback foundation inside the same runtime. Phase 112 adds deterministic
environmental reactions for the existing Home interactions. Phase 113
production-hardens the environmental reaction layer without adding new gameplay
scope. Phase 114 adds deterministic atmospheric progression inside the same runtime.

The runtime is owned by `Chapter0HomeCoordinator` at `src/ServerScriptService/Chapter0Home/Core`. It creates a bounded `Workspace.Chapter0Home` environment at startup, including a start spawn, a sitting room, hall, bedroom-door area, and four server-tagged interactables.

The playable loop is:

1. Spawn at `Chapter0HomeStart`.
2. Read Mum's note.
3. Turn the gas lamp.
4. Pick up Marmalade's ribbon.
5. Optionally open the bedroom door.

Completion requires the first three interactions. Progress is tracked per player on the server.

Phase 111 adds deterministic atmospheric feedback plans for the same four
interactions:

- Mum's note produces the `chapter0_home_note_read` prompt feedback plan.
- The gas lamp produces the `chapter0_home_gas_lamp_breath` visual feedback plan.
- Marmalade's ribbon produces the `chapter0_home_ribbon_found` prompt feedback plan.
- The optional bedroom door produces the `chapter0_home_bedroom_door_resists`
  screen-effect feedback plan without completing the chapter.

The plans are metadata only and are sent through the existing Player Experience
`Feedback_v1` RemoteEvent configured by `FeedbackService`. Phase 111 does not add
new remotes or a second presentation framework.

Phase 112 adds deterministic environmental reaction definitions for the same four
interactions:

- Mum's note marks the sitting room as attentive.
- The gas lamp applies a bounded warmth state to the lamp interactable.
- Marmalade's ribbon applies quiet pressure to the hall.
- The optional bedroom door applies a resistance state without completing the
  chapter.

Reactions are applied as server-owned attributes on instances inside the owned
`Workspace.Chapter0Home` root only. They are not final art, final audio, cinematic
events, monster behavior, or client-owned truth.

Runtime hardening verifies that optional interactions do not complete the chapter,
player removal clears only the departing player's progress, repeated interactions do
not corrupt completion state, per-player progress remains bounded, and malformed or
sparse content definitions cannot create Workspace content.

## Boundaries

- Uses the existing `PlayerExperienceService` and `LondonInteractable` tag.
- Adds no new remotes.
- Adds no DataStore writes.
- Adds no analytics or telemetry.
- Mutates only the owned `Workspace.Chapter0Home` folder.
- Does not implement monster encounters, Chapter 1, final art, final audio, cutscenes, or save persistence.

## Reset

`Chapter0HomeCoordinator.reset()` destroys and recreates only owned
`Workspace.Chapter0Home` roots marked with the runtime owner attributes, refuses to
overwrite unowned folders with the same name, clears per-player progress, and rebuilds
the authored room/interactable graph deterministically.

## Phase 110 Hardening

Phase 110 adds explicit protection for duplicate tags, duplicate room connections,
unsupported schema fields, unsafe Vector3 coordinates and dimensions, cycle-safe
serialization, bounded validation-failure history, owned-root diagnostics, and
idempotent reset/shutdown cleanup. The runtime still uses the existing
PlayerExperience remote contract and does not create a second Chapter 0 gameplay
system.

## Phase 111 Atmospheric Feedback

Phase 111 extends the Chapter 0 Home definition with canonical
`atmosphericFeedback` entries. Each entry has a stable feedback id, interaction
reference, supported Player Experience feedback kind, instruction id, bounded
intensity, optional bounded duration, deterministic order, and lowerCamelCase
metadata.

Feedback history is tracked per player in Chapter0Home state and is bounded by
`Types.Limits.MaxFeedbackHistoryPerPlayer`. Reset and shutdown clear the history
with the rest of the owned Chapter 0 Home state. Player removal clears only the
departing player's feedback history.

## Phase 112 Environmental Reactions

Phase 112 extends the Chapter 0 Home definition with canonical
`environmentalReactions` entries. Each entry has a stable reaction id, interaction
reference, reaction kind, target kind, target id, deterministic order, bounded
intensity, and lowerCamelCase metadata.

Reaction history is tracked per player and bounded by
`Types.Limits.MaxEnvironmentalReactionHistoryPerPlayer`. Reactions mutate only
attributes on runtime-owned Chapter 0 Home instances and are cleared by reset because
the owned root is destroyed and rebuilt deterministically.

## Phase 113 Environmental Reaction Hardening

Phase 113 freezes the environmental reaction schema posture in code and
documentation. Reaction attribute names are defined centrally in
`Types.EnvironmentalReactionAttributeNames`, metadata projection uses the stable
`Types.EnvironmentalReactionAttributePrefix`, and snapshots expose those names for
review.

The hardening verifies exact reaction ids, exact target references, root-target
rejection, reaction definition limits, metadata limits, scalar-only attribute
projection, diagnostics posture, snapshot evidence, and Phase 112 regression
protection. It does not create new reactions, new remotes, a new runtime, client
authority, persistence, Monster AI, combat, inventory, final art, final audio, or
Chapter 1 content.

## Phase 114 Atmospheric Progression

Phase 114 extends the Chapter 0 Home definition with canonical
`atmosphericProgressionStages` and `atmosphericProgressionTransitions`. The
progression is per-player, server-owned, and deterministic:

- initial quiet state: `chapter0_home_quiet_initial`;
- Mum's note: `chapter0_home_note_acknowledged`;
- gas lamp: `chapter0_home_lamp_unsteady_comfort`;
- Marmalade's ribbon: `chapter0_home_ribbon_quiet_escalation`;
- optional bedroom door: bounded non-blocking modifier only.

Transitions reference the existing interaction ids, atmospheric feedback ids, and
environmental reaction ids. They do not create new remotes, a duplicate feedback
system, a duplicate environmental reaction system, client authority, final audio,
final art, cutscenes, Monster AI, combat, inventory, save execution, or Chapter 1
content.

Progression state is stored in existing Chapter0Home per-player progress:
`progressionStageId`, `progressionTransitions`, `progressionHistory`, and
`optionalAtmosphericModifiers`. Histories and optional modifiers are bounded by
`Types.Limits`, repeated transitions are idempotent, reset clears progression state,
and player removal clears only the departing player's progression state.

## Phase 115 Atmospheric Progression Hardening

Phase 115 freezes the Phase 114 progression contract without adding gameplay scope.
Stable progression review surfaces now live in `Chapter0HomeTypes`: exact stage
definitions, exact transition definitions, exact initial stage id, exact transition
reference bindings, exact optional-modifier identity, progression limits, and
lowerCamelCase posture keys.

`Chapter0HomeConfig` consumes those canonical definitions instead of duplicating
progression values. `Chapter0HomeValidation` rejects stage-count drift,
transition-count drift, id drift, order drift, initial-stage drift, reference drift,
required-interaction sequence drift, completion relevance drift, intensity drift,
metadata drift, unsafe payloads, and unsupported fields before startup or mutation.

`Chapter0HomeState.recordAtmosphericProgression` accepts only exact canonical
transition payloads. Unknown transitions, malformed payloads, and out-of-order
canonical transitions fail before progression state advances. Optional modifiers are
stored separately and cannot advance the current stage or complete the chapter.
Repeated transitions remain idempotent.

## Runtime Certification

Phase 110 runtime certification is owned by
`ServerScriptService.Chapter0Home.Studio.Phase110CertificationRunner`. The runner is
Studio-only, requires explicit Workspace attribute `LondonPhase110RunSelfChecks =
true`, uses the shared Chapter0Home Studio self-check runner, verifies required
upstream PlayerExperience, Interaction Runtime, and Observation Engine regressions,
and restores temporary Chapter0Home runtime state after execution.

## Phase 116 Observation Integration

Phase 116 adds a narrow, server-authoritative integration boundary from Chapter 0
Home source state to the existing Observation Runtime. `Chapter0HomeCoordinator`
remains the source-state owner. Observation Engine remains the observation
processing owner.

The runtime defines seven canonical observation facts in `Chapter0HomeTypes` and
projects them through `Observation.Submitted` only after matching server-approved
Chapter 0 interactions and progression stage state exist. Per-player observation
integration state stores emitted fact ids, bounded history, deterministic sequence,
source progression stage, and optional modifier observations. Reset, shutdown, and
player removal clear this integration evidence with the rest of Chapter 0 state.

This phase does not add interactions, progression stages, feedback plans,
environmental reactions, remotes, client authority, persistence, Monster AI, combat,
inventory, save execution, cutscenes, final presentation, or Chapter 1 content.

## Phase 117 Observation Integration Hardening

Phase 117 freezes the Phase 116 observation integration contract without adding new
observation facts or gameplay consequences. Publication remains on the existing
`Observation.Submitted` EventBus signal and is allowed only when the player exists,
the signal identity matches the centralized contract, the source interaction has
been accepted, and the current progression stage exactly matches the canonical fact
stage.

The runtime centralizes the publication signal name, Chapter observation signal
name, optional observation modifier fact id, metadata schema keys, source-reference
schema, snapshot schema names, posture keys, and limits in `Chapter0HomeTypes`.
Observation integration state remains bounded per player and cannot become Chapter
progression truth.

## Phase 118 Runtime Certification Review

Phase 118 does not change Chapter 0 Home gameplay behavior. It adds a Studio-only,
explicit-gate certification review entry point that invokes existing Chapter 0 Home,
Player Experience, Interaction Runtime, Observation Engine, RemoteManager, reset,
cleanup, diagnostics, and snapshot self-check surfaces through the shared Studio
runner. The runner inspects and reports evidence only; it does not become a runtime
owner, Observation Engine, Chapter runtime, networking surface, persistence surface,
or gameplay authority.

## Phase 119 Certification Runtime Boundary

Phase 119 hardens the certification infrastructure only. The Chapter runtime,
Observation Engine, interaction surfaces, presentation surfaces, and player
progression remain unchanged. `Phase118CertificationContract` owns evidence schema
constants and `Phase118CertificationRunner` owns Studio-only certification evidence.

The hardened runner rejects recursive and concurrent invocations, sets its active
marker only after preflight succeeds, clears only its owned Workspace attributes,
and uses the contract's single certification decision function. It still does not
load assets, create remotes, mutate gameplay state, persist data, grant client
authority, add observation facts, add interactions, or add Chapter 1 content.

## Phase 120 Evidence Capture Boundary

Phase 120 adds no runtime behavior. It records that authoritative Studio execution
for `Phase118CertificationRunner` is blocked until the repository has a supported
non-interactive Studio capture workflow. The evidence artifact is documentation
only and does not create a Chapter runtime, Observation runtime, networking surface,
persistence surface, client authority surface, gameplay authority surface, or
alternate certification decision engine.
## Phase 121 Studio Evidence Capture Boundary

Phase 121 does not change Chapter 0 Home runtime behavior. It adds local
certification tooling that records whether the existing Studio-only Phase 118
runner can be executed and captured through a supported repository workflow.

The command `npm run london:certify:phase120` writes ignored local evidence
artifacts only. It does not mutate Chapter 0 state, create remotes, publish
observations, change presentation, write persistence, or execute gameplay.

## Phase 122 Studio Automation Bridge Runtime Boundary

Phase 122 adds only local Node automation. It does not run inside Roblox servers,
does not mutate Workspace, does not create or call remotes, does not publish
observations, and does not execute Chapter 0 gameplay. Its only runtime contact is
classification of whether the existing Studio-gated certification runner can be
invoked through a supported repository workflow.

## Phase 123 Structured Capture Runtime Boundary

Phase 123 adds no Roblox runtime behavior. Structured capture detection runs only
in local Node automation, does not execute gameplay, does not mutate Workspace,
does not create remotes, and does not publish observations. It only decides whether
a supported structured result can be captured and forwarded.

## Phase 124 MCP Activation Runtime Boundary

Phase 124 adds only local MCP activation checks. It does not invoke the Studio
runner unless every prerequisite is present, does not mutate Roblox runtime state,
does not create remotes, and does not generate runtime evidence.

## Phase 125 MCP Runner Binding Runtime Boundary

Phase 125 adds only local runner-binding diagnostics. It does not invoke Studio,
does not execute the runner, does not mutate Roblox runtime state, and does not
generate runtime evidence without a documented connected-session command.

## Phase 126 Connected Studio MCP Session Runtime Boundary

Phase 126 adds only local session-validation automation. It does not invoke Studio,
does not execute the runner, does not mutate Roblox runtime state, and does not
generate runtime evidence. It classifies whether a real connected Studio MCP
session identity is visible before any future runner authority can proceed.

## Phase 127 Studio MCP Runner Authority Runtime Boundary

Phase 127 adds only local runner lifecycle orchestration. It does not invoke
Studio, does not execute `Phase118CertificationRunner`, does not mutate Roblox
runtime state, does not generate runtime evidence, and does not certify gameplay.
It classifies future runner requests and blocks them unless every upstream
authority is actually ready.

## Phase 128 Runner Authority Contract Boundary

Phase 128 hardens the same local Runner Authority without changing runtime
behavior. It freezes contract version metadata, request schema, lifecycle
transitions, diagnostics, timeout policy, retry policy, cancellation policy, and
audit trail validation.

The hardened authority still does not invoke Studio, execute the runner, mutate
Roblox runtime state, generate runtime evidence, or certify gameplay.
## Phase 129 Studio MCP Integration Contract

Phase 129 adds a tooling-only Studio MCP integration contract authority in
`automation/studio-mcp-integration-contract.mjs`. It defines protocol metadata,
handshake transitions, capability negotiation, envelope schemas, compatibility,
serialization, and diagnostics for future external Studio MCP implementations.

It does not change Chapter 0 gameplay runtime behavior and preserves
`executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.

## Phase 130 Studio MCP Capability Negotiation Authority

Phase 130 adds a tooling-only capability negotiation authority in
`automation/studio-capability-negotiation-authority.mjs`. It validates advertised
Studio MCP capabilities and freezes negotiated profiles without changing Chapter 0
gameplay runtime behavior.

## Phase 131 Studio MCP Execution Readiness Authority

Phase 131 adds a tooling-only execution readiness authority in
`automation/studio-execution-readiness-authority.mjs`. It aggregates upstream
authority posture into one readiness decision without executing Studio or changing
Chapter 0 gameplay runtime behavior.

## Phase 132 Studio MCP Execution Planning Authority

Phase 132 adds a tooling-only execution planning authority in
`automation/studio-execution-planning-authority.mjs`. It consumes the Phase 131
readiness result and publishes immutable execution plans, execution graphs,
ordered planning stages, and checkpoints for future execution work.

The authority does not execute Studio, invoke the runner, capture runtime
evidence, mutate gameplay, create networking transport, write persistence, or
decide certification. Runtime truth remains `SESSION_NOT_VISIBLE`,
`executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.

## Phase 133 Studio MCP Execution Orchestrator

Phase 133 adds a tooling-only execution orchestrator in
`automation/studio-execution-orchestrator.mjs`. It consumes the Phase 132
execution plan and publishes immutable orchestration graphs, orchestration stages,
checkpoint references, execution context, retry metadata, and cancellation
metadata for future execution work.

The authority does not execute Studio, invoke the runner, capture runtime
evidence, mutate gameplay, create networking transport, write persistence, or
decide certification. Runtime truth remains `SESSION_NOT_VISIBLE`,
`executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.
