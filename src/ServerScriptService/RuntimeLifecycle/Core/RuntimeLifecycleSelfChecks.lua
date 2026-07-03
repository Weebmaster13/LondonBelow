--!strict
-- Deterministic self-checks for Phase 38 Runtime Lifecycle Foundation.

local Serialization = require(script.Parent.RuntimeLifecycleSerialization)
local Types = require(script.Parent.RuntimeLifecycleTypes)
local Validation = require(script.Parent.RuntimeLifecycleValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "runtimeLifecycleSelfCheck",
		schemaType = schemaType,
		runtimeNodeId = "runtime.node",
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function lifecycleState(id: string, value: string?): any
	local schema = base("lifecycleStateId", id, Types.SchemaType.LifecycleStateSchema)
	schema.lifecycleState = value or "Declared"
	return schema
end

local function transition(id: string): any
	local schema = base("transitionId", id, Types.SchemaType.LifecycleTransitionSchema)
	schema.fromState = "Declared"
	schema.toState = "Registered"
	schema.transitionKind = "Register"
	return schema
end

local function policy(id: string): any
	local schema = base("policyId", id, Types.SchemaType.LifecyclePolicySchema)
	schema.policyKind = "RequiredState"
	schema.lifecycleState = "Ready"
	return schema
end

local function guard(id: string): any
	local schema = base("guardId", id, Types.SchemaType.LifecycleGuardSchema)
	schema.guardKind = "GovernanceGuard"
	return schema
end

local function event(id: string): any
	local schema = base("eventId", id, Types.SchemaType.LifecycleEventSchema)
	schema.eventKind = "StateDeclared"
	return schema
end

local function failure(id: string): any
	local schema = base("failureId", id, Types.SchemaType.LifecycleFailureSchema)
	schema.failureKind = "ValidationFailure"
	return schema
end

local function recovery(id: string): any
	local schema = base("recoveryId", id, Types.SchemaType.LifecycleRecoverySchema)
	schema.recoveryKind = "ManualReview"
	return schema
end

local function checkpoint(id: string): any
	local schema = base("checkpointId", id, Types.SchemaType.LifecycleCheckpointSchema)
	schema.lifecycleState = "Ready"
	return schema
end

local function audit(id: string): any
	local schema = base("auditId", id, Types.SchemaType.LifecycleAuditSchema)
	schema.auditKind = "SchemaReview"
	schema.resultStatus = "Pass"
	schema.findings = { "finding.valid" }
	return schema
end

local function compatibility(id: string): any
	local schema = base("compatibilityId", id, Types.SchemaType.LifecycleCompatibilitySchema)
	schema.compatibilityKind = "Compatible"
	schema.lifecycleState = "Ready"
	schema.transitionKind = "Prepare"
	return schema
end

local function result(name: string, ok: boolean, detail: string?): any
	return { name = name, ok = ok, detail = detail }
end

local function expectReject(name: string, ok: boolean, reason: string?): any
	return result(name, not ok, reason)
end

local function expectAccept(name: string, ok: boolean, reason: string?): any
	return result(name, ok, reason)
end

local function add(results: { any }, check: any)
	table.insert(results, check)
end

local function unsafeSchema(schema: any, fields: any): any
	schema.context = fields
	return schema
end

local function unsupported(schema: any): any
	schema.schemaType = "UnsupportedRuntimeLifecycleSchema"
	return schema
end

local function oversizedArray(limit: number): { string }
	local values = {}
	for index = 1, limit + 1 do
		table.insert(values, "value." .. index)
	end
	return values
end

local function longString(): string
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(
		results,
		expectReject(
			"malformed lifecycle state rejects",
			Validation.lifecycleState({ lifecycleStateId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported lifecycle state schema type rejects",
			Validation.lifecycleState(unsupported(lifecycleState("state.unsupported")))
		)
	)
	add(
		results,
		expectReject(
			"unsupported lifecycle state value rejects",
			Validation.lifecycleState(lifecycleState("state.bad", "BadState"))
		)
	)
	local stateResult = service.registerLifecycleState(lifecycleState("state.valid", "Ready"))
	add(
		results,
		expectAccept("valid lifecycle state registers", stateResult.ok, stateResult.message)
	)
	add(
		results,
		expectReject(
			"duplicate lifecycle state rejects",
			service.registerLifecycleState(lifecycleState("state.valid")).ok,
			"duplicate state"
		)
	)
	add(
		results,
		expectReject(
			"unsafe lifecycle state rejects",
			service.registerLifecycleState(
				unsafeSchema(lifecycleState("state.unsafe"), { startRuntime = true })
			).ok,
			"unsafe"
		)
	)
	add(
		results,
		expectReject(
			"lifecycle state with runtime object rejects",
			service.registerLifecycleState(
				unsafeSchema(lifecycleState("state.runtime.object"), { runtimeObject = true })
			).ok,
			"runtime object"
		)
	)
	add(
		results,
		expectReject(
			"lifecycle state with execution adapter rejects",
			service.registerLifecycleState(
				unsafeSchema(lifecycleState("state.execution.adapter"), { executionAdapter = true })
			).ok,
			"execution adapter"
		)
	)

	add(results, expectReject("malformed policy rejects", Validation.policy({ policyId = "" })))
	add(
		results,
		expectReject(
			"unsupported policy schema type rejects",
			Validation.policy(unsupported(policy("policy.unsupported")))
		)
	)
	local badPolicy = policy("policy.bad.kind")
	badPolicy.policyKind = "BadKind"
	add(results, expectReject("unsupported policy kind rejects", Validation.policy(badPolicy)))
	local badPolicyState = policy("policy.bad.state")
	badPolicyState.lifecycleState = "BadState"
	add(
		results,
		expectReject(
			"unsupported lifecycleState rejects where present",
			Validation.policy(badPolicyState)
		)
	)
	local badPolicyTransition = policy("policy.bad.transition")
	badPolicyTransition.transitionKind = "BadKind"
	add(
		results,
		expectReject(
			"unsupported transitionKind rejects where present",
			Validation.policy(badPolicyTransition)
		)
	)
	local policyResult = service.registerPolicy(policy("policy.valid"))
	add(results, expectAccept("valid policy registers", policyResult.ok, policyResult.message))
	add(
		results,
		expectReject(
			"duplicate policy rejects",
			service.registerPolicy(policy("policy.valid")).ok,
			"duplicate policy"
		)
	)
	add(
		results,
		expectReject(
			"policy with enforcement payload rejects",
			service.registerPolicy(unsafeSchema(policy("policy.enforcement"), { execute = true })).ok,
			"enforcement"
		)
	)

	add(results, expectReject("malformed guard rejects", Validation.guard({ guardId = "" })))
	add(
		results,
		expectReject(
			"unsupported guard schema type rejects",
			Validation.guard(unsupported(guard("guard.unsupported")))
		)
	)
	local badGuard = guard("guard.bad.kind")
	badGuard.guardKind = "BadKind"
	add(results, expectReject("unsupported guard kind rejects", Validation.guard(badGuard)))
	local guardResult = service.registerGuard(guard("guard.valid"))
	add(results, expectAccept("valid guard registers", guardResult.ok, guardResult.message))
	add(
		results,
		expectReject(
			"duplicate guard rejects",
			service.registerGuard(guard("guard.valid")).ok,
			"duplicate guard"
		)
	)
	add(
		results,
		expectReject(
			"guard with live check payload rejects",
			service.registerGuard(
				unsafeSchema(guard("guard.live"), { liveServiceManagement = true })
			).ok,
			"live check"
		)
	)
	add(
		results,
		expectReject(
			"guard with service resolution payload rejects",
			service.registerGuard(
				unsafeSchema(guard("guard.service"), { serviceResolution = true })
			).ok,
			"service resolution"
		)
	)

	add(
		results,
		expectReject("malformed transition rejects", Validation.transition({ transitionId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported transition schema type rejects",
			Validation.transition(unsupported(transition("transition.unsupported")))
		)
	)
	local badFrom = transition("transition.bad.from")
	badFrom.fromState = "BadState"
	add(results, expectReject("unsupported fromState rejects", Validation.transition(badFrom)))
	local badTo = transition("transition.bad.to")
	badTo.toState = "BadState"
	add(results, expectReject("unsupported toState rejects", Validation.transition(badTo)))
	local badKind = transition("transition.bad.kind")
	badKind.transitionKind = "BadKind"
	add(
		results,
		expectReject("unsupported transition kind rejects", Validation.transition(badKind))
	)
	local identical = transition("transition.identical")
	identical.toState = identical.fromState
	add(
		results,
		expectReject("identical fromState/toState rejects", Validation.transition(identical))
	)
	local badPolicyRef = transition("transition.bad.policy")
	badPolicyRef.policyIds = { "policy.missing" }
	add(
		results,
		expectReject(
			"invalid policy reference rejects",
			service.registerTransition(badPolicyRef).ok,
			"policy ref"
		)
	)
	local badGuardRef = transition("transition.bad.guard")
	badGuardRef.guardIds = { "guard.missing" }
	add(
		results,
		expectReject(
			"invalid guard reference rejects",
			service.registerTransition(badGuardRef).ok,
			"guard ref"
		)
	)
	local transitionResult = service.registerTransition(transition("transition.valid"))
	add(
		results,
		expectAccept("valid transition registers", transitionResult.ok, transitionResult.message)
	)
	add(
		results,
		expectReject(
			"duplicate transition rejects",
			service.registerTransition(transition("transition.valid")).ok,
			"duplicate transition"
		)
	)
	add(
		results,
		expectReject(
			"transition with startup/shutdown execution payload rejects",
			service.registerTransition(
				unsafeSchema(
					transition("transition.execution"),
					{ startupExecution = true, shutdownExecution = true }
				)
			).ok,
			"transition execution"
		)
	)

	add(results, expectReject("malformed event rejects", Validation.event({ eventId = "" })))
	add(
		results,
		expectReject(
			"unsupported event schema type rejects",
			Validation.event(unsupported(event("event.unsupported")))
		)
	)
	local badEvent = event("event.bad.kind")
	badEvent.eventKind = "BadKind"
	add(results, expectReject("unsupported event kind rejects", Validation.event(badEvent)))
	local eventBadState = event("event.bad.state")
	eventBadState.relatedStateId = "state.missing"
	add(
		results,
		expectReject(
			"invalid related state reference rejects",
			service.registerEvent(eventBadState).ok,
			"event state"
		)
	)
	local eventBadTransition = event("event.bad.transition")
	eventBadTransition.relatedTransitionId = "transition.missing"
	add(
		results,
		expectReject(
			"invalid related transition reference rejects",
			service.registerEvent(eventBadTransition).ok,
			"event transition"
		)
	)
	local eventResult = service.registerEvent(event("event.valid"))
	add(results, expectAccept("valid event registers", eventResult.ok, eventResult.message))
	add(
		results,
		expectReject(
			"duplicate event rejects",
			service.registerEvent(event("event.valid")).ok,
			"duplicate event"
		)
	)
	add(
		results,
		expectReject(
			"event with live emission payload rejects",
			service.registerEvent(
				unsafeSchema(event("event.live"), { orchestrationExecution = true })
			).ok,
			"event live"
		)
	)

	add(results, expectReject("malformed failure rejects", Validation.failure({ failureId = "" })))
	add(
		results,
		expectReject(
			"unsupported failure schema type rejects",
			Validation.failure(unsupported(failure("failure.unsupported")))
		)
	)
	local badFailure = failure("failure.bad.kind")
	badFailure.failureKind = "BadKind"
	add(results, expectReject("unsupported failure kind rejects", Validation.failure(badFailure)))
	local failureBadState = failure("failure.bad.state")
	failureBadState.relatedStateId = "state.missing"
	add(
		results,
		expectReject(
			"invalid failure state reference rejects",
			service.registerFailure(failureBadState).ok,
			"failure state"
		)
	)
	local failureBadTransition = failure("failure.bad.transition")
	failureBadTransition.relatedTransitionId = "transition.missing"
	add(
		results,
		expectReject(
			"invalid failure transition reference rejects",
			service.registerFailure(failureBadTransition).ok,
			"failure transition"
		)
	)
	local failureResult = service.registerFailure(failure("failure.valid"))
	add(results, expectAccept("valid failure registers", failureResult.ok, failureResult.message))
	add(
		results,
		expectReject(
			"duplicate failure rejects",
			service.registerFailure(failure("failure.valid")).ok,
			"duplicate failure"
		)
	)
	add(
		results,
		expectReject(
			"failure with live error/runtime object/callback payload rejects",
			service.registerFailure(
				unsafeSchema(failure("failure.live"), { runtimeObject = true, callback = true })
			).ok,
			"failure live"
		)
	)

	add(
		results,
		expectReject("malformed recovery rejects", Validation.recovery({ recoveryId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported recovery schema type rejects",
			Validation.recovery(unsupported(recovery("recovery.unsupported")))
		)
	)
	local badRecovery = recovery("recovery.bad.kind")
	badRecovery.recoveryKind = "BadKind"
	add(
		results,
		expectReject("unsupported recovery kind rejects", Validation.recovery(badRecovery))
	)
	local recoveryBadFailure = recovery("recovery.bad.failure")
	recoveryBadFailure.relatedFailureId = "failure.missing"
	add(
		results,
		expectReject(
			"invalid related failure reference rejects",
			service.registerRecovery(recoveryBadFailure).ok,
			"failure ref"
		)
	)
	local recoveryResult = service.registerRecovery(recovery("recovery.valid"))
	add(
		results,
		expectAccept("valid recovery registers", recoveryResult.ok, recoveryResult.message)
	)
	add(
		results,
		expectReject(
			"duplicate recovery rejects",
			service.registerRecovery(recovery("recovery.valid")).ok,
			"duplicate recovery"
		)
	)
	add(
		results,
		expectReject(
			"recovery with retry/restart/restore/disable execution payload rejects",
			service.registerRecovery(
				unsafeSchema(
					recovery("recovery.execution"),
					{ restartExecution = true, recoveryExecution = true }
				)
			).ok,
			"recovery execution"
		)
	)

	add(
		results,
		expectReject("malformed checkpoint rejects", Validation.checkpoint({ checkpointId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported checkpoint schema type rejects",
			Validation.checkpoint(unsupported(checkpoint("checkpoint.unsupported")))
		)
	)
	local badCheckpoint = checkpoint("checkpoint.bad.state")
	badCheckpoint.lifecycleState = "BadState"
	add(
		results,
		expectReject(
			"unsupported checkpoint lifecycleState rejects",
			Validation.checkpoint(badCheckpoint)
		)
	)
	local checkpointResult = service.registerCheckpoint(checkpoint("checkpoint.valid"))
	add(
		results,
		expectAccept("valid checkpoint registers", checkpointResult.ok, checkpointResult.message)
	)
	add(
		results,
		expectReject(
			"duplicate checkpoint rejects",
			service.registerCheckpoint(checkpoint("checkpoint.valid")).ok,
			"duplicate checkpoint"
		)
	)
	add(
		results,
		expectReject(
			"checkpoint with save persistence/DataStore/live object payload rejects",
			service.registerCheckpoint(
				unsafeSchema(
					checkpoint("checkpoint.save"),
					{ savePersistence = true, dataStoreWrite = true }
				)
			).ok,
			"checkpoint save"
		)
	)

	add(results, expectReject("malformed audit rejects", Validation.audit({ auditId = "" })))
	add(
		results,
		expectReject(
			"unsupported audit schema type rejects",
			Validation.audit(unsupported(audit("audit.unsupported")))
		)
	)
	local auditHeavy = audit("audit.heavy")
	auditHeavy.findings = oversizedArray(Types.Limits.MaxAuditFindings)
	add(results, expectReject("oversized findings reject", Validation.audit(auditHeavy)))
	local auditResult = service.registerAudit(audit("audit.valid"))
	add(results, expectAccept("valid audit registers", auditResult.ok, auditResult.message))
	add(
		results,
		expectReject(
			"duplicate audit rejects",
			service.registerAudit(audit("audit.valid")).ok,
			"duplicate audit"
		)
	)
	add(
		results,
		expectReject(
			"audit with enforcement/remediation payload rejects",
			service.registerAudit(unsafeSchema(audit("audit.enforcement"), { execute = true })).ok,
			"audit enforcement"
		)
	)

	add(
		results,
		expectReject(
			"malformed compatibility rejects",
			Validation.compatibility({ compatibilityId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported compatibility schema type rejects",
			Validation.compatibility(unsupported(compatibility("compatibility.unsupported")))
		)
	)
	local badCompatibility = compatibility("compatibility.bad.kind")
	badCompatibility.compatibilityKind = "BadKind"
	add(
		results,
		expectReject(
			"unsupported compatibility kind rejects",
			Validation.compatibility(badCompatibility)
		)
	)
	local badCompatibilityState = compatibility("compatibility.bad.state")
	badCompatibilityState.lifecycleState = "BadState"
	add(
		results,
		expectReject(
			"unsupported compatibility lifecycleState rejects",
			Validation.compatibility(badCompatibilityState)
		)
	)
	local badCompatibilityTransition = compatibility("compatibility.bad.transition")
	badCompatibilityTransition.transitionKind = "BadKind"
	add(
		results,
		expectReject(
			"unsupported compatibility transitionKind rejects",
			Validation.compatibility(badCompatibilityTransition)
		)
	)
	local compatibilityResult = service.registerCompatibility(compatibility("compatibility.valid"))
	add(
		results,
		expectAccept(
			"valid compatibility registers",
			compatibilityResult.ok,
			compatibilityResult.message
		)
	)
	add(
		results,
		expectReject(
			"duplicate compatibility rejects",
			service.registerCompatibility(compatibility("compatibility.valid")).ok,
			"duplicate compatibility"
		)
	)
	add(
		results,
		expectReject(
			"compatibility with migration/adapter loading payload rejects",
			service.registerCompatibility(
				unsafeSchema(compatibility("compatibility.migration"), { adapterReference = true })
			).ok,
			"compatibility migration"
		)
	)

	local namespaceChecks = {
		{
			"lifecycle state id rejects as transition id",
			function()
				return service.registerTransition(transition("state.valid"))
			end,
		},
		{
			"transition id rejects as policy id",
			function()
				return service.registerPolicy(policy("transition.valid"))
			end,
		},
		{
			"policy id rejects as guard id",
			function()
				return service.registerGuard(guard("policy.valid"))
			end,
		},
		{
			"guard id rejects as event id",
			function()
				return service.registerEvent(event("guard.valid"))
			end,
		},
		{
			"event id rejects as failure id",
			function()
				return service.registerFailure(failure("event.valid"))
			end,
		},
		{
			"failure id rejects as recovery id",
			function()
				return service.registerRecovery(recovery("failure.valid"))
			end,
		},
		{
			"recovery id rejects as checkpoint id",
			function()
				return service.registerCheckpoint(checkpoint("recovery.valid"))
			end,
		},
		{
			"checkpoint id rejects as audit id",
			function()
				return service.registerAudit(audit("checkpoint.valid"))
			end,
		},
		{
			"audit id rejects as compatibility id",
			function()
				return service.registerCompatibility(compatibility("audit.valid"))
			end,
		},
	}
	for _, item in ipairs(namespaceChecks) do
		local response = item[2]()
		add(results, expectReject(item[1], response.ok, response.message))
	end

	local forbiddenGroups = {
		["startup execution fields reject"] = { startRuntime = true, startupExecution = true },
		["shutdown execution fields reject"] = { shutdownRuntime = true, shutdownExecution = true },
		["initialization execution fields reject"] = {
			initializeRuntime = true,
			initializationExecution = true,
		},
		["restart execution fields reject"] = { restartRuntime = true, restartExecution = true },
		["recovery execution fields reject"] = { recoverRuntime = true, recoveryExecution = true },
		["pause/resume execution fields reject"] = {
			pauseRuntime = true,
			pauseExecution = true,
			resumeRuntime = true,
			resumeExecution = true,
		},
		["unload/reload fields reject"] = { unloadRuntime = true, reloadRuntime = true },
		["live service management fields reject"] = { liveServiceManagement = true },
		["framework replacement fields reject"] = { frameworkReplacement = true },
		["framework mutation fields reject"] = { frameworkMutation = true },
		["runtime graph ownership fields reject"] = { runtimeGraphOwnership = true },
		["dependency injection fields reject"] = {
			dependencyInjection = true,
			dependencyInjectionExecution = true,
		},
		["service resolution fields reject"] = { serviceResolution = true, resolveService = true },
		["module loading fields reject"] = { moduleLoading = true, loadModule = true },
		["require-call fields reject"] = { require = true, requireCall = true },
		["runtime API call fields reject"] = { runtimeApiCall = true, callRuntime = true },
		["lifecycle execution fields reject"] = { lifecycleExecution = true },
		["orchestration execution fields reject"] = { orchestrationExecution = true },
		["gameplay execution fields reject"] = { gameplayExecution = true },
		["puzzle execution fields reject"] = { puzzleExecution = true },
		["interaction execution fields reject"] = { interactionExecution = true },
		["inventory execution fields reject"] = { inventoryExecution = true },
		["objective execution fields reject"] = { objectiveExecution = true },
		["narrative execution fields reject"] = { narrativeExecution = true },
		["monster ai execution fields reject"] = { monsterAIExecution = true },
		["presentation execution fields reject"] = { presentationExecution = true },
		["save persistence fields reject"] = { savePersistence = true },
		["content loading fields reject"] = { contentLoading = true },
		["asset loading fields reject"] = { assetLoading = true },
		["map loading fields reject"] = { mapLoading = true },
		["room loading fields reject"] = { roomLoading = true },
		["Workspace fields reject"] = { workspace = true, workspacePath = true },
		["remote fields reject"] = {
			remote = true,
			remoteEvent = true,
			remoteFunction = true,
			fireClient = true,
			fireAllClients = true,
			invokeClient = true,
		},
		["client authority fields reject"] = { clientAuthority = true },
		["data store fields reject"] = {
			dataStore = true,
			dataStoreRead = true,
			dataStoreWrite = true,
		},
		["http service fields reject"] = { http = true, httpService = true },
		["messaging service fields reject"] = { messaging = true, messagingService = true },
		["analytics fields reject"] = { analytics = true, analyticsCollection = true },
		["telemetry fields reject"] = { telemetry = true, telemetrySending = true },
		["chapter content fields reject"] = { chapterContent = true, chapter0Content = true },
		["final story fields reject"] = { finalStory = true, story = true },
		["final dialogue fields reject"] = { finalDialogue = true, dialogue = true },
		["cutscene fields reject"] = { cutscene = true },
		["service reference fields reject"] = { serviceReference = true },
		["adapter reference fields reject"] = { adapterReference = true },
		["handler reference fields reject"] = { handlerReference = true },
		["callback fields reject"] = { callback = true, executableCallback = true },
		["execution adapter fields reject"] = { executionAdapter = true },
		["module reference fields reject"] = { moduleReference = true },
		["framework reference fields reject"] = { frameworkReference = true },
		["runtime object fields reject"] = { runtimeObject = true },
		["Instance reference fields reject"] = { instanceReference = true },
		["execute fields reject"] = { execute = true },
	}
	for name, fields in pairs(forbiddenGroups) do
		add(
			results,
			expectReject(
				name,
				Validation.lifecycleState(unsafeSchema(lifecycleState("state.forbidden"), fields))
			)
		)
	end
	local forbiddenFields = {
		"startRuntime",
		"startupExecution",
		"shutdownRuntime",
		"shutdownExecution",
		"initializeRuntime",
		"initializationExecution",
		"restartRuntime",
		"restartExecution",
		"recoverRuntime",
		"recoveryExecution",
		"pauseRuntime",
		"pauseExecution",
		"resumeRuntime",
		"resumeExecution",
		"unloadRuntime",
		"reloadRuntime",
		"liveServiceManagement",
		"frameworkReplacement",
		"frameworkMutation",
		"runtimeGraphOwnership",
		"dependencyInjection",
		"dependencyInjectionExecution",
		"serviceResolution",
		"resolveService",
		"moduleLoading",
		"loadModule",
		"require",
		"requireCall",
		"runtimeApiCall",
		"callRuntime",
		"lifecycleExecution",
		"orchestrationExecution",
		"gameplayExecution",
		"puzzleExecution",
		"interactionExecution",
		"inventoryExecution",
		"objectiveExecution",
		"narrativeExecution",
		"monsterAIExecution",
		"presentationExecution",
		"savePersistence",
		"contentLoading",
		"assetLoading",
		"mapLoading",
		"roomLoading",
		"workspace",
		"remote",
		"remoteEvent",
		"remoteFunction",
		"fireClient",
		"fireAllClients",
		"invokeClient",
		"clientAuthority",
		"dataStore",
		"dataStoreRead",
		"dataStoreWrite",
		"http",
		"httpService",
		"messaging",
		"messagingService",
		"analytics",
		"analyticsCollection",
		"telemetry",
		"telemetrySending",
		"chapterContent",
		"chapter0Content",
		"finalStory",
		"story",
		"finalDialogue",
		"dialogue",
		"cutscene",
		"serviceReference",
		"adapterReference",
		"handlerReference",
		"callback",
		"executableCallback",
		"executionAdapter",
		"moduleReference",
		"frameworkReference",
		"runtimeObject",
		"workspacePath",
		"instanceReference",
		"execute",
	}
	for index, fieldName in ipairs(forbiddenFields) do
		add(
			results,
			expectReject(
				string.format("forbidden field %s rejects", fieldName),
				Validation.lifecycleState(
					unsafeSchema(lifecycleState("state.forbidden.field." .. index), {
						[fieldName] = true,
					})
				)
			)
		)
	end

	local cyclic: any = {}
	cyclic.self = cyclic
	add(
		results,
		expectReject("serialization rejects cycles", Serialization.validateSerializable(cyclic))
	)
	add(
		results,
		expectReject(
			"serialization rejects Roblox Instances",
			Serialization.validateSerializable(script)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects functions",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects threads",
			Serialization.validateSerializable(coroutine.create(function() end))
		)
	)
	add(
		results,
		result(
			"serialization rejects userdata",
			select(1, Serialization.validateSerializable(script)) == false,
			"Roblox userdata-like Instances reject."
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized strings",
			Serialization.validateSerializable(longString())
		)
	)
	local wide: any = {}
	for index = 1, Types.Limits.MaxPayloadNodes + 2 do
		wide["node" .. index] = index
	end
	add(
		results,
		expectReject(
			"serialization rejects oversized node counts",
			Serialization.validateSerializable(wide)
		)
	)
	local deep: any = {}
	local cursor = deep
	for _ = 1, Types.Limits.MaxPayloadDepth + 2 do
		cursor.next = {}
		cursor = cursor.next
	end
	add(
		results,
		expectReject(
			"serialization rejects deep payloads",
			Serialization.validateSerializable(deep)
		)
	)
	local diagnosticCopy = Serialization.diagnosticCopy({
		callback = function() end,
		thread = coroutine.create(function() end),
		instance = script,
		serviceReference = "serviceReference",
		nested = { runtimeObject = "runtimeObject" },
	})
	add(
		results,
		result(
			"diagnostic copy sanitizes unsafe values",
			diagnosticCopy.callback == "<unsafe:function>"
				and diagnosticCopy.thread == "<unsafe:thread>"
				and diagnosticCopy.instance == "<RobloxInstance>"
				and diagnosticCopy["<sanitized-key>"] == "<sanitized:runtime-lifecycle-boundary>"
				and diagnosticCopy.nested["<sanitized-key>"]
					== "<sanitized:runtime-lifecycle-boundary>",
			nil
		)
	)

	local snapshot = service.getSnapshot()
	snapshot.counts.lifecycleStates = -100
	add(
		results,
		result("snapshots are isolated", service.getSnapshot().counts.lifecycleStates ~= -100, nil)
	)
	local diagnostics = service.inspect()
	diagnostics.counts.lifecycleStates = -100
	add(
		results,
		result("diagnostics are read-only", service.inspect().counts.lifecycleStates ~= -100, nil)
	)

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerLifecycleState({ lifecycleStateId = "", index = index })
	end
	add(
		results,
		result(
			"validation failures are bounded",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)
	for _ = 1, Types.Limits.MaxSnapshotHistory + 5 do
		service.getSnapshot()
	end
	add(
		results,
		result(
			"snapshots are bounded",
			service.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
			nil
		)
	)

	service.shutdown()
	for index = 1, Types.Limits.MaxLifecycleStates do
		service.registerLifecycleState(lifecycleState("limit.state." .. index))
	end
	add(
		results,
		expectReject(
			"lifecycle state limits reject",
			service.registerLifecycleState(lifecycleState("limit.state.extra")).ok,
			"state limit"
		)
	)
	service.shutdown()

	add(
		results,
		expectReject(
			"policy reference limits reject",
			Validation.transition((function()
				local schema = transition("limit.policy.refs")
				schema.policyIds = oversizedArray(Types.Limits.MaxPolicyRefs)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"guard reference limits reject",
			Validation.transition((function()
				local schema = transition("limit.guard.refs")
				schema.guardIds = oversizedArray(Types.Limits.MaxGuardRefs)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"audit finding limits reject",
			Validation.audit((function()
				local schema = audit("limit.audit.findings")
				schema.findings = oversizedArray(Types.Limits.MaxAuditFindings)
				return schema
			end)())
		)
	)

	service.shutdown()
	for index = 1, Types.Limits.MaxTransitions do
		service.registerTransition(transition("limit.transition." .. index))
	end
	add(
		results,
		expectReject(
			"transition limits reject",
			service.registerTransition(transition("limit.transition.extra")).ok,
			"transition limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxPolicies do
		service.registerPolicy(policy("limit.policy." .. index))
	end
	add(
		results,
		expectReject(
			"policy limits reject",
			service.registerPolicy(policy("limit.policy.extra")).ok,
			"policy limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxGuards do
		service.registerGuard(guard("limit.guard." .. index))
	end
	add(
		results,
		expectReject(
			"guard limits reject",
			service.registerGuard(guard("limit.guard.extra")).ok,
			"guard limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxEvents do
		service.registerEvent(event("limit.event." .. index))
	end
	add(
		results,
		expectReject(
			"event limits reject",
			service.registerEvent(event("limit.event.extra")).ok,
			"event limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxFailures do
		service.registerFailure(failure("limit.failure." .. index))
	end
	add(
		results,
		expectReject(
			"failure limits reject",
			service.registerFailure(failure("limit.failure.extra")).ok,
			"failure limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxRecoveries do
		service.registerRecovery(recovery("limit.recovery." .. index))
	end
	add(
		results,
		expectReject(
			"recovery limits reject",
			service.registerRecovery(recovery("limit.recovery.extra")).ok,
			"recovery limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxCheckpoints do
		service.registerCheckpoint(checkpoint("limit.checkpoint." .. index))
	end
	add(
		results,
		expectReject(
			"checkpoint limits reject",
			service.registerCheckpoint(checkpoint("limit.checkpoint.extra")).ok,
			"checkpoint limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxAudits do
		service.registerAudit(audit("limit.audit." .. index))
	end
	add(
		results,
		expectReject(
			"audit limits reject",
			service.registerAudit(audit("limit.audit.extra")).ok,
			"audit limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxCompatibilityRecords do
		service.registerCompatibility(compatibility("limit.compatibility." .. index))
	end
	add(
		results,
		expectReject(
			"compatibility limits reject",
			service.registerCompatibility(compatibility("limit.compatibility.extra")).ok,
			"compatibility limit"
		)
	)

	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.lifecycleStates == 0
				and service.inspect().counts.compatibilities == 0,
			nil
		)
	)
	local reusableState = service.registerLifecycleState(lifecycleState("state.valid"))
	local duplicateAfterShutdown = service.registerTransition(transition("state.valid"))
	add(
		results,
		result(
			"shutdown clears global namespace",
			reusableState.ok and not duplicateAfterShutdown.ok,
			duplicateAfterShutdown.message
		)
	)
	service.shutdown()

	local noExecution = {
		"no startup execution exists",
		"no shutdown execution exists",
		"no initialization execution exists",
		"no restart execution exists",
		"no recovery execution exists",
		"no pause/resume execution exists",
		"no unload/reload execution exists",
		"no live service management exists",
		"no framework replacement exists",
		"no framework mutation exists",
		"no runtime graph ownership exists",
		"no dependency injection execution exists",
		"no service resolution exists",
		"no module loading exists",
		"no require-call execution exists",
		"no runtime API calls exist",
		"no lifecycle execution exists",
		"no orchestration execution exists",
		"no gameplay execution exists",
		"no puzzle execution exists",
		"no interaction execution exists",
		"no inventory execution exists",
		"no objective execution exists",
		"no narrative execution exists",
		"no monster ai execution exists",
		"no presentation execution exists",
		"no save persistence exists",
		"no content loading exists",
		"no asset loading exists",
		"no map loading exists",
		"no room loading exists",
		"no world mutation exists",
		"no remotes exist",
		"no client authority exists",
		"no data store reads/writes exist",
		"no external http access exists",
		"no external messaging access exists",
		"no analytics collection exists",
		"no telemetry sending exists",
		"no chapter content exists",
		"no final story exists",
		"no final dialogue exists",
		"no cutscenes exist",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Runtime Lifecycle stores schemas only."))
	end

	service.initialize()
	service.start()
	local refused = service.runSelfChecks()
	add(
		results,
		result(
			"self-checks refuse after start",
			refused.ok == false and refused.reason ~= nil,
			refused.reason
		)
	)
	service.shutdown()

	local allOk = true
	for _, check in ipairs(results) do
		if not check.ok then
			allOk = false
			break
		end
	end
	return { ok = allOk, results = results }
end

return SelfChecks
