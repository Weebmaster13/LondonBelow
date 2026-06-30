# London Engine Governance Layer

The Governance Layer makes the London Engine Constitution enforceable.

It is not gameplay, Monster AI, Chapter 1 content, final UI, or final art. It is a Core runtime subsystem that lets future systems declare their architecture contract and then validates that contract against the engine laws.

## Why Governance Exists

London Engine is designed to grow beyond 100,000 lines of Luau. Without governance, future systems could quietly become one-off scripts, bypass the Observation Engine, let Monster AI own horror pacing, skip diagnostics, or put gameplay truth on the client.

Governance prevents that drift by requiring every subsystem to state:

- System name.
- Owner layer.
- Responsibilities.
- What it does not own.
- Dependencies.
- Observations emitted.
- Director approvals required.
- Execution permissions.
- Client presentation allowed.
- Diagnostics exposed.
- Snapshot providers.
- Cleanup behavior.
- Multiplayer guarantees.
- Failure modes.
- Documentation.

## Runtime Modules

`ServerScriptService/Core/Governance` contains:

- `EngineGovernance.lua`: Framework-integrated lifecycle owner, registration API, validation orchestration, diagnostics, snapshots, and signals.
- `EngineContractTypes.lua`: strict contract and scorecard types.
- `EngineContractRegistry.lua`: contract registration and built-in contracts for current major systems.
- `EngineContractValidator.lua`: constitution checks and structured issues.
- `DirectorContract.lua`: standard future Director interface.
- `ObservationContract.lua`: standard observation definition rules.
- `ExecutionContract.lua`: standard execution system rules.
- `EngineScorecard.lua`: structured 100000/10 scoring categories.
- `GovernanceDiagnostics.lua`: diagnostics and validation aggregation.
- `GovernanceSignals.lua`: EventBus signal names.

## Current Registered Contracts

Governance registers foundation contracts for:

- Core Runtime.
- Lobby Runtime.
- Portal Runtime.
- Observation Engine.
- Psychological Horror Director.

Existing systems are not forced to add code-level registration yet. Future systems should register contracts as part of their implementation.

## Future System Registration

A future subsystem should call `EngineGovernance.registerContract(contract)` during startup or central registration. The contract should be reviewed alongside the code.

Minimal shape:

```lua
EngineGovernance.registerContract({
	systemName = "Door Runtime",
	ownerLayer = "Gameplay",
	status = "Production",
	responsibilities = {
		"door state",
		"lock validation",
		"open and close requests",
	},
	doesNotOwn = {
		"horror pacing",
		"monster movement",
		"client-owned door truth",
	},
	dependencies = {
		"Core Runtime",
		"Observation Engine",
		"RemoteManager",
	},
	observationsEmitted = {
		{ id = "Interaction.OpenDoor", when = "server opens door", required = true },
		{ id = "Interaction.DoorHesitation", when = "server detects hesitation", required = true },
	},
	directorApprovalsRequired = {
		{
			director = "Environment",
			reason = "cinematic door reaction",
			requiredFor = { "unscripted slam", "distant door close" },
		},
	},
	executionPermissions = {
		{ action = "open door", requiresApproval = false, approval = nil },
	},
	clientPresentation = {
		allowed = true,
		description = "client may animate prompts and play approved local effects",
		mustBeServerApproved = true,
	},
	diagnosticsExposed = { "DoorService.inspect" },
	snapshotProviders = { "doors" },
	cleanupBehavior = { "disconnect prompts", "clear per-run door state" },
	multiplayerGuarantees = { "server-owned lock state", "late join receives current state" },
	failureModes = { "reject invalid proximity", "fail closed if config missing" },
	documentation = { "DOOR_RUNTIME.md" },
	tags = { "gameplay", "doors" },
})
```

## What Governance Checks

Governance validates declared contracts for:

- No client-owned gameplay truth.
- No bypassing Observation Engine for gameplay facts.
- No major horror events without Director approval.
- No duplicate remote ownership outside `RemoteManager`.
- No God-system responsibility drift.
- No missing diagnostics for production systems.
- No missing cleanup path.
- No missing documentation.
- No circular-style ownership violations.
- No Monster AI owning horror pacing.
- No execution system inventing pacing decisions.

Governance is not a full source-code static analyzer. It makes architecture obligations explicit and inspectable, then code review and tests enforce the implementation.

## Severity And Health

Governance issues are structured and severity-based:

- `Pass`: the contract currently satisfies validation.
- `Info`: useful context that does not indicate risk.
- `Warning`: design pressure that should be reviewed before the subsystem grows.
- `Error`: a constitutional violation that blocks production readiness.
- `Fatal`: a malformed contract or invalid schema that cannot be trusted.

The Governance health state is derived from the latest validation summary:

- `NotValidated`: validation has not run or Governance has shut down.
- `Healthy`: no errors or warnings were found.
- `Warning`: at least one warning exists, but no blocking errors exist.
- `Failed`: at least one error or fatal issue exists.

Framework startup refuses Governance contracts with `Error` or `Fatal` issues. Warnings are visible in diagnostics and startup logs so future work can decide whether to split, document, or redesign a subsystem before it becomes expensive.

## Director Contract

Future Directors should expose:

- `initialize`
- `start`
- `shutdown`
- `observe`
- `requestApproval`
- `getSnapshot`
- `getDiagnostics`
- `validate`

Directors interpret Observation Engine truth and publish approvals. They do not execute physical gameplay actions directly.

## Observation Contract

Future observation definitions must declare:

- Stable namespaced ID.
- Category.
- Expected metadata.
- Source system.
- Security level.
- Aggregation rule.
- Expiration rule.
- Director forwarding rules.

Clients never create trusted observations.

## Execution Contract

Execution systems:

- Execute approved decisions when approval is required.
- Fail safely.
- Emit observations when creating new truth.
- Expose diagnostics.
- Clean up tasks and connections.

Execution systems do not invent pacing decisions.

## Scorecard

`EngineScorecard` produces structured scores for:

- Single responsibility.
- Server authority.
- Observation output.
- Director integration.
- Diagnostics.
- Snapshot support.
- Cleanup.
- Multiplayer safety.
- Documentation.
- Extensibility.
- Failure safety.

A system is not 100000/10 because it is large. It is 100000/10 when it has one clear job, protects truth, plugs into the engine cleanly, can be inspected, fails safely, and makes future work easier.

Scorecards now include:

- `passed`: true only when there are no blocking governance issues and the system scores at least 80%.
- `grade`: `Excellent`, `Good`, `Weak`, or `Failing`.
- Category scores that make missing diagnostics, snapshots, cleanup, multiplayer safety, documentation, and failure modes expensive instead of cosmetic.

Production systems cannot pass by leaving these fields empty. Gameplay-truth systems must declare observation output. Major horror surfaces must declare Director approval. Execution systems must declare what they are allowed to execute and whether approval is required.

## Passing Design Example

Door Runtime passes when it:

- Owns only door state and lock validation.
- Emits `Interaction.OpenDoor`, `Interaction.CloseDoor`, and `Interaction.DoorHesitation`.
- Requires Environment Director approval for cinematic door scares.
- Uses RemoteManager for client requests.
- Exposes diagnostics and snapshots.
- Cleans up prompts and per-run state.
- Fails closed when configuration is invalid.

## Failing Design Example

A script fails governance if it:

- Lives in a random chapter folder.
- Plays a jumpscare directly.
- Moves the monster directly.
- Does not emit observations.
- Does not ask any Director for approval.
- Stores fear truth on the client.
- Has no diagnostics.
- Has no cleanup path.

That is not London Engine architecture.

## Weak Design Example

A weak contract might technically avoid errors but still score poorly:

```lua
EngineGovernance.registerContract({
	systemName = "Fog Runtime",
	ownerLayer = "Execution",
	status = "Foundation",
	responsibilities = { "fog changes", "local ambience" },
	doesNotOwn = { "horror pacing", "client truth" },
	dependencies = { "Core Runtime" },
	observationsEmitted = {},
	directorApprovalsRequired = {
		{
			director = "Environment",
			reason = "fog changes can imply building attention",
			requiredFor = { "heavy fog swell" },
		},
	},
	executionPermissions = {
		{ action = "apply approved fog pressure", requiresApproval = true, approval = "Environment" },
	},
	clientPresentation = {
		allowed = true,
		description = "client may render approved fog visuals",
		mustBeServerApproved = true,
	},
	diagnosticsExposed = {},
	snapshotProviders = {},
	cleanupBehavior = {},
	multiplayerGuarantees = {},
	failureModes = {},
	documentation = {},
	tags = { "execution", "environment" },
})
```

This is not production-ready because it lacks diagnostics, snapshots, cleanup, multiplayer guarantees, failure modes, and documentation. It should stay `Foundation` until those obligations exist.

## Failing Contract Example

This contract should fail:

```lua
EngineGovernance.registerContract({
	systemName = "Monster Brain",
	ownerLayer = "AI",
	status = "Production",
	responsibilities = {
		"monster movement",
		"horror pacing",
		"chapter climax",
		"scare selection",
	},
	doesNotOwn = { "client presentation" },
	dependencies = { "Core Runtime" },
	observationsEmitted = {},
	directorApprovalsRequired = {},
	executionPermissions = {},
	clientPresentation = {
		allowed = false,
		description = "server-only AI",
		mustBeServerApproved = true,
	},
	diagnosticsExposed = {},
	snapshotProviders = {},
	cleanupBehavior = {},
	multiplayerGuarantees = {},
	failureModes = {},
	documentation = {},
	tags = { "monster", "ai" },
})
```

It fails because Monster AI cannot own horror pacing, climax, or scare selection; production systems cannot omit diagnostics, snapshots, cleanup, multiplayer guarantees, failure modes, or documentation; and the contract does not clearly state enough non-ownership boundaries.

## How Codex Should Use Governance

For future subsystem work, Codex should:

1. Read `LONDON_ENGINE.md`, `ENGINE_CONSTITUTION.md`, and this document.
2. Define the subsystem contract before or alongside implementation.
3. Register the contract with `EngineGovernance`.
4. Run governance validation through normal Framework validation.
5. Add subsystem docs.
6. Run all checks before committing.

Governance is the guardrail that keeps London Below from turning into a collection of unrelated horror scripts.
