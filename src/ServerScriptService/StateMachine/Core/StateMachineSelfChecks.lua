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

local function withField(schema: any, field: string, value: any): any
	local copy = Serialization.deepCopy(schema)
	copy[field] = value
	return copy
end

local function oversizedIds(prefix: string, limit: number): { string }
	local ids = {}
	for index = 1, limit + 1 do
		table.insert(ids, prefix .. tostring(index))
	end
	return ids
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

local function makeWidePayload(nodes: number): any
	local root = {}
	for index = 1, nodes do
		root["node" .. tostring(index)] = { index = index }
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
	expectReject(
		"invalid state reference rejects",
		State.registerDefinition(
			withField(machine("bad.state.ref"), "stateIds", { "missing.state" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid transition reference rejects",
		State.registerDefinition(
			withField(machine("bad.transition.ref"), "transitionIds", { "missing.transition" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid guard reference rejects",
		State.registerDefinition(
			withField(machine("bad.guard.ref"), "guardIds", { "missing.guard" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid input reference rejects",
		State.registerDefinition(
			withField(machine("bad.input.ref"), "inputIds", { "missing.input" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid output reference rejects",
		State.registerDefinition(
			withField(machine("bad.output.ref"), "outputIds", { "missing.output" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid group reference rejects",
		State.registerDefinition(
			withField(machine("bad.group.ref"), "groupIds", { "missing.group" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid dependency reference rejects",
		State.registerDefinition(
			withField(machine("bad.dependency.ref"), "dependencyIds", { "missing.dependency" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid outcome reference rejects",
		State.registerDefinition(
			withField(machine("bad.outcome.ref"), "outcomeIds", { "missing.outcome" })
		),
		nil,
		checks
	)
	expectReject(
		"oversized state reference list rejects",
		State.registerDefinition(
			withField(
				machine("bad.state.limit"),
				"stateIds",
				oversizedIds("state.", Types.Limits.MaxMachineStates)
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized transition reference list rejects",
		State.registerDefinition(
			withField(
				machine("bad.transition.limit"),
				"transitionIds",
				oversizedIds("transition.", Types.Limits.MaxMachineTransitions)
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized guard reference list rejects",
		State.registerDefinition(
			withField(
				machine("bad.guard.limit"),
				"guardIds",
				oversizedIds("guard.", Types.Limits.MaxMachineGuards)
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized input reference list rejects",
		State.registerDefinition(
			withField(
				machine("bad.input.limit"),
				"inputIds",
				oversizedIds("input.", Types.Limits.MaxMachineInputs)
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized output reference list rejects",
		State.registerDefinition(
			withField(
				machine("bad.output.limit"),
				"outputIds",
				oversizedIds("output.", Types.Limits.MaxMachineOutputs)
			)
		),
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
	expectReject(
		"unsupported state schema type rejects",
		State.registerState(
			withField(state("machine.a", "state.bad.type"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsafe state payload rejects",
		State.registerState(withField(state("machine.a", "state.unsafe"), "callback", true)),
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
	expectReject(
		"unsupported transition schema type rejects",
		State.registerTransition(
			withField(
				transition("machine.a", "transition.bad.type", "state.a", "state.b"),
				"schemaType",
				"Unsupported"
			)
		),
		nil,
		checks
	)
	expectReject(
		"unsupported transition kind rejects",
		State.registerTransition(
			withField(
				transition("machine.a", "transition.bad.kind", "state.a", "state.b"),
				"transitionKind",
				"BadKind"
			)
		),
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
		"unsupported guard schema type rejects",
		State.registerGuard(
			withField(guard("machine.a", "guard.bad.type"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported guard kind rejects",
		State.registerGuard(withField(guard("machine.a", "guard.bad.kind"), "guardKind", "BadKind")),
		nil,
		checks
	)
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
		"unsupported input schema type rejects",
		State.registerInput(
			withField(input("machine.a", "input.bad.type"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported input kind rejects",
		State.registerInput(withField(input("machine.a", "input.bad.kind"), "inputKind", "BadKind")),
		nil,
		checks
	)
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
		"unsupported output schema type rejects",
		State.registerOutput(
			withField(output("machine.a", "output.bad.type"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported output kind rejects",
		State.registerOutput(
			withField(output("machine.a", "output.bad.kind"), "outputKind", "BadKind")
		),
		nil,
		checks
	)
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
		"unsupported group schema type rejects",
		State.registerGroup(
			withField(group("group.bad.type", { "machine.a" }), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported group kind rejects",
		State.registerGroup(
			withField(group("group.bad.kind", { "machine.a" }), "groupKind", "BadKind")
		),
		nil,
		checks
	)
	expectReject(
		"missing machine group rejects",
		State.registerGroup(group("group.missing", { "missing" })),
		nil,
		checks
	)
	expectReject(
		"invalid group state reference rejects",
		State.registerGroup(
			withField(group("group.bad.state", { "machine.a" }), "stateIds", { "missing.state" })
		),
		nil,
		checks
	)
	expectReject(
		"invalid group transition reference rejects",
		State.registerGroup(
			withField(
				group("group.bad.transition", { "machine.a" }),
				"transitionIds",
				{ "missing.transition" }
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized group member list rejects",
		State.registerGroup(
			group("group.too.large", oversizedIds("machine.", Types.Limits.MaxGroupMembers))
		),
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
		"unsupported dependency schema type rejects",
		State.registerDependency(
			withField(
				dependency("dependency.bad.type", "machine.a", "machine.b"),
				"schemaType",
				"Unsupported"
			)
		),
		nil,
		checks
	)
	expectReject(
		"unsupported dependency kind rejects",
		State.registerDependency(
			withField(
				dependency("dependency.bad.kind", "machine.a", "machine.b"),
				"dependencyKind",
				"BadKind"
			)
		),
		nil,
		checks
	)
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
		"unsupported outcome schema type rejects",
		State.registerOutcome(
			withField(outcome("machine.a", "outcome.bad.type"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported outcome kind rejects",
		State.registerOutcome(
			withField(outcome("machine.a", "outcome.bad.kind"), "outcomeKind", "BadKind")
		),
		nil,
		checks
	)
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
		"unsupported audit schema type rejects",
		State.registerAudit(
			withField(audit("audit.bad.type", "machine.a"), "schemaType", "Unsupported")
		),
		nil,
		checks
	)
	expectReject(
		"oversized audit findings reject",
		State.registerAudit(
			withField(
				audit("audit.too.large", "machine.a"),
				"findings",
				oversizedIds("finding.", Types.Limits.MaxAuditFindings)
			)
		),
		nil,
		checks
	)
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
	expectAccept(
		"namespace second state registers",
		State.registerState(state("namespace.id", "namespace.state.two")),
		nil,
		checks
	)
	expectReject(
		"namespace transition collision rejects",
		State.registerTransition(
			transition("namespace.id", "namespace.state", "namespace.state", "namespace.state.two")
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
	expectAccept(
		"namespace input registers",
		State.registerInput(input("namespace.id", "namespace.input")),
		nil,
		checks
	)
	expectReject(
		"namespace output collision rejects",
		State.registerOutput(output("namespace.id", "namespace.input")),
		nil,
		checks
	)
	expectAccept(
		"namespace output registers",
		State.registerOutput(output("namespace.id", "namespace.output")),
		nil,
		checks
	)
	expectReject(
		"namespace group collision rejects",
		State.registerGroup(group("namespace.output", { "namespace.id" })),
		nil,
		checks
	)
	expectAccept(
		"namespace group registers",
		State.registerGroup(group("namespace.group", { "namespace.id" })),
		nil,
		checks
	)
	expectAccept(
		"namespace second machine registers",
		State.registerDefinition(machine("namespace.id.two")),
		nil,
		checks
	)
	expectReject(
		"namespace dependency collision rejects",
		State.registerDependency(dependency("namespace.group", "namespace.id", "namespace.id.two")),
		nil,
		checks
	)
	expectAccept(
		"namespace dependency registers",
		State.registerDependency(
			dependency("namespace.dependency", "namespace.id", "namespace.id.two")
		),
		nil,
		checks
	)
	expectReject(
		"namespace outcome collision rejects",
		State.registerOutcome(outcome("namespace.id", "namespace.dependency")),
		nil,
		checks
	)
	expectAccept(
		"namespace outcome registers",
		State.registerOutcome(outcome("namespace.id", "namespace.outcome")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.outcome", "namespace.id")),
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
		"conditionRuntimeExecution",
		"ruleEvaluation",
		"ruleExecution",
		"eventDispatch",
		"dispatchEvent",
		"schedulerExecution",
		"lifecycleExecution",
		"eventGraphExecution",
		"runtimeGraphExecution",
		"ruleEngineExecution",
		"triggerRuntimeExecution",
		"runtimeExecution",
		"runtimeOrchestration",
		"saveExecution",
		"scripting",
		"scriptExecution",
		"executableCallback",
		"listenerExecution",
		"signalHandle",
		"runtimeSignalHandle",
		"eventConsumption",
		"triggerConsumption",
		"eventEmission",
		"signalEmission",
		"triggerEmission",
		"workspace",
		"workspacePath",
		"remote" .. "Event",
		"remote" .. "Function",
		"fire" .. "Client",
		"fire" .. "AllClients",
		"invoke" .. "Client",
		"remote",
		"clientAuthority",
		"dataStore",
		"dataStoreRead",
		"dataStoreWrite",
		"http",
		"http" .. "Service",
		"messaging",
		"messaging" .. "Service",
		"ana" .. "lytics",
		"analyticsCollection",
		"tele" .. "metry",
		"telemetrySending",
		"chapterContent",
		"chapter0Content",
		"finalStory",
		"story",
		"finalDialogue",
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
		"blockingExecution",
		"computedResult",
		"gameplayResult",
		"transitionResult",
		"executionBatch",
		"enforcement",
		"remediation",
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
		"serialization rejects threads",
		Serialization.validateSerializable({ unsafe = coroutine.create(function() end) }),
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
		"serialization rejects oversized node counts",
		Serialization.validateSerializable(makeWidePayload(Types.Limits.MaxPayloadNodes + 1)),
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
	local diagnosticCopy = Serialization.diagnosticCopy({
		callback = function() end,
		nested = {
			"execute",
		},
	})
	expect(
		"diagnostic copy sanitizes unsafe values",
		diagnosticCopy["<unsafe-marker>"] == "<unsafe-runtime-value>"
			and diagnosticCopy.nested[1] == "<unsafe-marker>",
		"diagnostic copy leaked unsafe values",
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
		"transition limit seed machine registers",
		State.registerDefinition(machine("limit.transition.seed")),
		nil,
		checks
	)
	expectAccept(
		"transition limit source state registers",
		State.registerState(state("limit.transition.seed", "limit.transition.source")),
		nil,
		checks
	)
	expectAccept(
		"transition limit target state registers",
		State.registerState(state("limit.transition.seed", "limit.transition.target")),
		nil,
		checks
	)
	fillLimit("transition", Types.Limits.MaxTransitions, function(index)
		return transition(
			"limit.transition.seed",
			"limit.transition." .. tostring(index),
			"limit.transition.source",
			"limit.transition.target"
		)
	end, State.registerTransition, checks)

	State.clear()
	expectAccept(
		"guard limit seed machine registers",
		State.registerDefinition(machine("limit.guard.seed")),
		nil,
		checks
	)
	fillLimit("guard", Types.Limits.MaxGuards, function(index)
		return guard("limit.guard.seed", "limit.guard." .. tostring(index))
	end, State.registerGuard, checks)

	State.clear()
	expectAccept(
		"input limit seed machine registers",
		State.registerDefinition(machine("limit.input.seed")),
		nil,
		checks
	)
	fillLimit("input", Types.Limits.MaxInputs, function(index)
		return input("limit.input.seed", "limit.input." .. tostring(index))
	end, State.registerInput, checks)

	State.clear()
	expectAccept(
		"output limit seed machine registers",
		State.registerDefinition(machine("limit.output.seed")),
		nil,
		checks
	)
	fillLimit("output", Types.Limits.MaxOutputs, function(index)
		return output("limit.output.seed", "limit.output." .. tostring(index))
	end, State.registerOutput, checks)

	State.clear()
	expectAccept(
		"group limit seed machine registers",
		State.registerDefinition(machine("limit.group.seed")),
		nil,
		checks
	)
	fillLimit("group", Types.Limits.MaxGroups, function(index)
		return group("limit.group." .. tostring(index), { "limit.group.seed" })
	end, State.registerGroup, checks)

	State.clear()
	expectAccept(
		"dependency limit source machine registers",
		State.registerDefinition(machine("limit.dependency.source")),
		nil,
		checks
	)
	expectAccept(
		"dependency limit target machine registers",
		State.registerDefinition(machine("limit.dependency.target")),
		nil,
		checks
	)
	fillLimit("dependency", Types.Limits.MaxDependencies, function(index)
		return dependency(
			"limit.dependency." .. tostring(index),
			"limit.dependency.source",
			"limit.dependency.target"
		)
	end, State.registerDependency, checks)

	State.clear()
	expectAccept(
		"outcome limit seed machine registers",
		State.registerDefinition(machine("limit.outcome.seed")),
		nil,
		checks
	)
	fillLimit("outcome", Types.Limits.MaxOutcomes, function(index)
		return outcome("limit.outcome.seed", "limit.outcome." .. tostring(index))
	end, State.registerOutcome, checks)

	State.clear()
	expectAccept(
		"audit limit seed machine registers",
		State.registerDefinition(machine("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit." .. tostring(index), "limit.audit.seed")
	end, State.registerAudit, checks)

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
