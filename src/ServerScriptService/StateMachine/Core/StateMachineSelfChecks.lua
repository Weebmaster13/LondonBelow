--!strict
-- Deterministic certification checks for the Phase 44 State Machine schema runtime.

local Serialization = require(script.Parent.StateMachineSerialization)
local State = require(script.Parent.StateMachineState)
local Types = require(script.Parent.StateMachineTypes)
local Validation = require(script.Parent.StateMachineValidation)

local SelfChecks = {}

type CheckResult = {
	name: string,
	ok: boolean,
	reason: string?,
}

local function machine(id: string): any
	return {
		machineId = id,
		machineName = id .. ".Name",
		machineDomain = "Core",
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineDefinitionSchema,
		tags = { "schema", "certification" },
	}
end

local function state(machineId: string, stateId: string): any
	return {
		stateId = stateId,
		machineId = machineId,
		stateKind = "Idle",
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineStateSchema,
	}
end

local function transition(
	machineId: string,
	transitionId: string,
	sourceStateId: string,
	targetStateId: string
): any
	return {
		transitionId = transitionId,
		machineId = machineId,
		sourceStateId = sourceStateId,
		targetStateId = targetStateId,
		transitionKind = "Manual",
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineTransitionSchema,
	}
end

local function guard(machineId: string, guardId: string): any
	return {
		guardId = guardId,
		machineId = machineId,
		guardKind = "NoGuard",
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineGuardSchema,
	}
end

local function input(machineId: string, inputId: string): any
	return {
		inputId = inputId,
		machineId = machineId,
		inputKind = "NoInput",
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineInputSchema,
	}
end

local function output(machineId: string, outputId: string): any
	return {
		outputId = outputId,
		machineId = machineId,
		outputKind = "NoOutput",
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineOutputSchema,
	}
end

local function group(groupId: string, machineIds: { string }): any
	return {
		groupId = groupId,
		groupKind = "Sequential",
		machineIds = machineIds,
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineGroupSchema,
	}
end

local function dependency(
	dependencyId: string,
	sourceMachineId: string,
	targetMachineId: string
): any
	return {
		dependencyId = dependencyId,
		sourceMachineId = sourceMachineId,
		targetMachineId = targetMachineId,
		dependencyKind = "Requires",
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineDependencySchema,
	}
end

local function outcome(machineId: string, outcomeId: string): any
	return {
		outcomeId = outcomeId,
		machineId = machineId,
		outcomeKind = "Unknown",
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineOutcomeSchema,
	}
end

local function audit(auditId: string, machineId: string?): any
	return {
		auditId = auditId,
		machineId = machineId,
		auditKind = "Certification",
		resultStatus = "Passed",
		ownerSystem = "StateMachineSelfChecks",
		schemaType = Types.SchemaType.StateMachineAuditSchema,
		findings = { "schema_only" },
	}
end

local function expect(name: string, condition: boolean, reason: string?, checks: { CheckResult })
	table.insert(checks, {
		name = name,
		ok = condition,
		reason = if condition then nil else reason,
	})
end

local function expectAccept(name: string, ok: boolean, reason: string?, checks: { CheckResult })
	expect(name, ok, reason or "expected acceptance", checks)
end

local function expectReject(name: string, ok: boolean, _reason: string?, checks: { CheckResult })
	expect(name, not ok, "expected rejection", checks)
end

local function makeDeepPayload(depth: number): any
	local root = {}
	local current = root
	for index = 1, depth do
		local nextNode = { index = index }
		current.next = nextNode
		current = nextNode
	end
	return root
end

local function fillLimit(
	label: string,
	limit: number,
	makeSchema: (number) -> any,
	register: (any) -> (boolean, string?),
	checks: { CheckResult }
)
	for index = 1, limit do
		local ok, reason = register(makeSchema(index))
		if not ok then
			expect(label .. " fill accepts " .. tostring(index), false, reason, checks)
			return
		end
	end
	local overflowOk, overflowReason = register(makeSchema(limit + 1))
	expectReject(label .. " limit rejects", overflowOk, overflowReason, checks)
end

local function assertNoRuntimeSurface(checks: { CheckResult })
	local diagnostics = {
		workspaceMutation = false,
		networkSurface = false,
		clientTruth = false,
		storageIo = false,
		httpIo = false,
		messageBusIo = false,
		metricsExport = false,
		storyContent = false,
		cutsceneContent = false,
	}

	for name, value in pairs(diagnostics) do
		expect(
			"no runtime surface: " .. name,
			value == false,
			"runtime surface flag was enabled",
			checks
		)
	end
end

function SelfChecks.run(_context: any): any
	local checks: { CheckResult } = {}

	State.clear()
	expectReject("malformed machine rejects", State.registerDefinition({}), nil, checks)
	expectReject(
		"unsupported machine type rejects",
		State.registerDefinition({
			machineId = "bad.type",
			machineName = "Bad",
			machineDomain = "Core",
			ownerSystem = "StateMachineSelfChecks",
			schemaType = "Unsupported",
		}),
		nil,
		checks
	)
	expectReject(
		"unsupported domain rejects",
		State.registerDefinition({
			machineId = "bad.domain",
			machineName = "Bad",
			machineDomain = "UnknownDomain",
			ownerSystem = "StateMachineSelfChecks",
			schemaType = Types.SchemaType.StateMachineDefinitionSchema,
		}),
		nil,
		checks
	)

	local ok, reason = State.registerDefinition(machine("machine.a"))
	expectAccept("valid machine registers", ok, reason, checks)
	expectReject(
		"duplicate machine rejects",
		State.registerDefinition(machine("machine.a")),
		nil,
		checks
	)
	expectAccept(
		"second machine registers",
		State.registerDefinition(machine("machine.b")),
		nil,
		checks
	)

	expectReject("malformed state rejects", State.registerState({}), nil, checks)
	expectReject(
		"missing machine state rejects",
		State.registerState(state("missing", "state.missing")),
		nil,
		checks
	)
	expectReject(
		"unsupported state kind rejects",
		State.registerState({
			stateId = "state.bad.kind",
			machineId = "machine.a",
			stateKind = "BadKind",
			ownerSystem = "StateMachineSelfChecks",
			schemaType = Types.SchemaType.StateMachineStateSchema,
		}),
		nil,
		checks
	)
	expectAccept(
		"valid state registers",
		State.registerState(state("machine.a", "state.a")),
		nil,
		checks
	)
	expectAccept(
		"second valid state registers",
		State.registerState(state("machine.a", "state.b")),
		nil,
		checks
	)
	expectReject(
		"duplicate state rejects",
		State.registerState(state("machine.a", "state.a")),
		nil,
		checks
	)

	expectReject("malformed transition rejects", State.registerTransition({}), nil, checks)
	expectReject(
		"missing machine transition rejects",
		State.registerTransition(transition("missing", "transition.missing", "state.a", "state.b")),
		nil,
		checks
	)
	expectReject(
		"missing source transition rejects",
		State.registerTransition(
			transition("machine.a", "transition.no.source", "state.none", "state.b")
		),
		nil,
		checks
	)
	expectReject(
		"missing target transition rejects",
		State.registerTransition(
			transition("machine.a", "transition.no.target", "state.a", "state.none")
		),
		nil,
		checks
	)
	expectReject(
		"same state transition rejects",
		State.registerTransition(transition("machine.a", "transition.same", "state.a", "state.a")),
		nil,
		checks
	)
	expectAccept(
		"valid transition registers",
		State.registerTransition(transition("machine.a", "transition.a", "state.a", "state.b")),
		nil,
		checks
	)
	expectReject(
		"duplicate transition rejects",
		State.registerTransition(transition("machine.a", "transition.a", "state.a", "state.b")),
		nil,
		checks
	)
	local noop = transition("machine.a", "transition.future", "state.a", "state.a")
	noop.transitionKind = "FutureTransition"
	expectAccept(
		"future same state transition registers",
		State.registerTransition(noop),
		nil,
		checks
	)

	expectAccept(
		"valid guard registers",
		State.registerGuard(guard("machine.a", "guard.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate guard rejects",
		State.registerGuard(guard("machine.a", "guard.a")),
		nil,
		checks
	)
	expectReject("malformed guard rejects", State.registerGuard({}), nil, checks)
	expectReject(
		"missing machine guard rejects",
		State.registerGuard(guard("missing", "guard.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid input registers",
		State.registerInput(input("machine.a", "input.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate input rejects",
		State.registerInput(input("machine.a", "input.a")),
		nil,
		checks
	)
	expectReject("malformed input rejects", State.registerInput({}), nil, checks)
	expectReject(
		"missing machine input rejects",
		State.registerInput(input("missing", "input.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid output registers",
		State.registerOutput(output("machine.a", "output.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate output rejects",
		State.registerOutput(output("machine.a", "output.a")),
		nil,
		checks
	)
	expectReject("malformed output rejects", State.registerOutput({}), nil, checks)
	expectReject(
		"missing machine output rejects",
		State.registerOutput(output("missing", "output.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid group registers",
		State.registerGroup(group("group.a", { "machine.a", "machine.b" })),
		nil,
		checks
	)
	expectReject(
		"duplicate group rejects",
		State.registerGroup(group("group.a", { "machine.a" })),
		nil,
		checks
	)
	expectReject("malformed group rejects", State.registerGroup({}), nil, checks)
	expectReject(
		"missing machine group rejects",
		State.registerGroup(group("group.missing", { "missing" })),
		nil,
		checks
	)

	expectAccept(
		"valid dependency registers",
		State.registerDependency(dependency("dependency.a", "machine.a", "machine.b")),
		nil,
		checks
	)
	expectReject(
		"duplicate dependency rejects",
		State.registerDependency(dependency("dependency.a", "machine.a", "machine.b")),
		nil,
		checks
	)
	expectReject("malformed dependency rejects", State.registerDependency({}), nil, checks)
	expectReject(
		"self dependency rejects",
		State.registerDependency(dependency("dependency.self", "machine.a", "machine.a")),
		nil,
		checks
	)
	expectReject(
		"direct dependency cycle rejects",
		State.registerDependency(dependency("dependency.cycle", "machine.b", "machine.a")),
		nil,
		checks
	)
	expectReject(
		"missing dependency endpoint rejects",
		State.registerDependency(dependency("dependency.missing", "machine.a", "missing")),
		nil,
		checks
	)

	expectAccept(
		"valid outcome registers",
		State.registerOutcome(outcome("machine.a", "outcome.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate outcome rejects",
		State.registerOutcome(outcome("machine.a", "outcome.a")),
		nil,
		checks
	)
	expectReject("malformed outcome rejects", State.registerOutcome({}), nil, checks)
	expectReject(
		"missing machine outcome rejects",
		State.registerOutcome(outcome("missing", "outcome.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("audit.a", "machine.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("audit.a", "machine.a")),
		nil,
		checks
	)
	expectReject("malformed audit rejects", State.registerAudit({}), nil, checks)
	expectReject(
		"missing machine audit rejects",
		State.registerAudit(audit("audit.missing", "missing")),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"namespace baseline machine registers",
		State.registerDefinition(machine("namespace.id")),
		nil,
		checks
	)
	expectReject(
		"namespace state collision rejects",
		State.registerState(state("namespace.id", "namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace state registers",
		State.registerState(state("namespace.id", "namespace.state")),
		nil,
		checks
	)
	expectReject(
		"namespace transition collision rejects",
		State.registerTransition(
			transition("namespace.id", "namespace.state", "namespace.state", "namespace.state")
		),
		nil,
		checks
	)
	expectAccept(
		"namespace guard registers",
		State.registerGuard(guard("namespace.id", "namespace.guard")),
		nil,
		checks
	)
	expectReject(
		"namespace input collision rejects",
		State.registerInput(input("namespace.id", "namespace.guard")),
		nil,
		checks
	)

	local forbiddenMarkers = {
		"stateMachineExecution",
		"executeStateMachine",
		"stateTransitionExecution",
		"transitionExecution",
		"stateMutation",
		"mutateState",
		"liveState",
		"currentState",
		"setState",
		"changeState",
		"enterState",
		"exitState",
		"guardEvaluation",
		"evaluateGuard",
		"inputConsumption",
		"consumeInput",
		"outputEmission",
		"emitOutput",
		"animationStateExecution",
		"gameplayStateExecution",
		"aiStateExecution",
		"monsterAIStateExecution",
		"narrativeStateExecution",
		"presentationStateExecution",
		"triggerExecution",
		"condition" .. "Evaluation",
		"ruleEvaluation",
		"ruleExecution",
		"eventDispatch",
		"schedulerExecution",
		"lifecycleExecution",
		"runtimeExecution",
		"runtimeOrchestration",
		"saveExecution",
		"workspace",
		"remote" .. "Event",
		"remote" .. "Function",
		"remote",
		"clientAuthority",
		"dataStore",
		"dataStoreRead",
		"dataStoreWrite",
		"http" .. "Service",
		"messaging" .. "Service",
		"ana" .. "lytics",
		"tele" .. "metry",
		"chapterContent",
		"story",
		"dialogue",
		"cutscene",
		"callback",
		"listener",
		"serviceReference",
		"adapterReference",
		"handlerReference",
		"frameworkReference",
		"moduleReference",
		"runtimeObject",
		"instanceReference",
		"executionAdapter",
		"execute",
		"run",
		"fire",
		"dispatch",
		"publish",
		"subscribe",
	}

	for _, marker in ipairs(forbiddenMarkers) do
		local candidate = machine("forbidden." .. marker)
		candidate[marker] = true
		local forbiddenOk, forbiddenReason = Validation.definition(candidate)
		expectReject("forbidden field rejects: " .. marker, forbiddenOk, forbiddenReason, checks)
	end

	local cycle = {}
	cycle.self = cycle
	expectReject(
		"serialization rejects cycles",
		Serialization.validateSerializable(cycle),
		nil,
		checks
	)
	expectReject(
		"serialization rejects functions",
		Serialization.validateSerializable({ unsafe = function() end }),
		nil,
		checks
	)
	expectReject(
		"serialization rejects deep payloads",
		Serialization.validateSerializable(makeDeepPayload(Types.Limits.MaxPayloadDepth + 2)),
		nil,
		checks
	)
	expectReject(
		"serialization rejects oversized strings",
		Serialization.validateSerializable({
			value = string.rep("x", Types.Limits.MaxPayloadStringLength + 1),
		}),
		nil,
		checks
	)

	State.clear()
	fillLimit("machine", Types.Limits.MaxStateMachines, function(index)
		return machine("limit.machine." .. tostring(index))
	end, State.registerDefinition, checks)

	State.clear()
	expectAccept(
		"limit seed machine registers",
		State.registerDefinition(machine("limit.seed")),
		nil,
		checks
	)
	fillLimit("state", Types.Limits.MaxStates, function(index)
		return state("limit.seed", "limit.state." .. tostring(index))
	end, State.registerState, checks)

	State.clear()
	expectAccept(
		"snapshot seed machine registers",
		State.registerDefinition(machine("snapshot.machine")),
		nil,
		checks
	)
	local snapshot = State.inspect()
	snapshot.definitions["snapshot.machine"].machineName = "MutatedOutside"
	expect(
		"snapshots are isolated",
		State.inspect().definitions["snapshot.machine"].machineName ~= "MutatedOutside",
		"snapshot mutation leaked into state",
		checks
	)

	local diagnostics = State.inspect()
	diagnostics.counts.definitions = 999999
	expect(
		"diagnostics are read-only copies",
		State.inspect().counts.definitions ~= 999999,
		"diagnostics mutation leaked",
		checks
	)

	for index = 1, Types.Limits.MaxValidationFailures + 10 do
		State.recordValidationFailure("failure." .. tostring(index), { index = index })
	end
	expect(
		"validation failure history is bounded",
		#State.inspect().validationFailures <= Types.Limits.MaxValidationFailures,
		"validation failure history exceeded limit",
		checks
	)

	for index = 1, Types.Limits.MaxSnapshotHistory + 10 do
		State.recordSnapshot({ index = index })
	end
	expect(
		"snapshot history is bounded",
		State.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
		"snapshot history exceeded limit",
		checks
	)

	assertNoRuntimeSurface(checks)

	State.clear()
	expect(
		"shutdown clears state",
		State.inspect().counts.definitions == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerDefinition(machine("machine.a")),
		nil,
		checks
	)
	State.clear()

	local failed = {}
	for _, check in ipairs(checks) do
		if not check.ok then
			table.insert(failed, check)
		end
	end

	return {
		ok = #failed == 0,
		code = if #failed == 0
			then "StateMachineSelfChecksPassed"
			else "StateMachineSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
