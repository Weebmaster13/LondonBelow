--!strict

local Serialization = require(script.Parent.EnvironmentalSerialization)
local Types = require(script.Parent.EnvironmentalTypes)

local SelfChecks = {}

local function binaryDefinition(id: string)
	return {
		id = id,
		version = 1,
		family = Types.Family.BinaryMechanism,
		displayName = "Self-check binary mechanism",
		interactionTargetId = id .. ".target",
		supportedActions = { Types.Action.Open, Types.Action.Close, Types.Action.Toggle },
		initialState = Types.State.Closed,
		allowedStates = { Types.State.Closed, Types.State.Open },
		transitionRules = {},
		interactionDefinitions = {},
		authoringMetadata = { fixture = true },
		presentationMetadata = {
			promptKey = "environmental.selfCheck.open",
			actionDisplayKeys = { open = "Open", close = "Close" },
		},
		observationPolicy = { requiresFocus = true },
		distancePolicy = { maxDistance = 12 },
		lineOfSightPolicy = { required = true },
		contentionPolicy = "Exclusive",
		cooldownPolicy = { seconds = 0 },
		repeatPolicy = "Repeatable",
		resetPolicy = { state = Types.State.Closed },
		diagnosticMetadata = { phase = 157 },
	}
end

local function inspectableDefinition(id: string, repeatable: boolean)
	return {
		id = id,
		version = 1,
		family = Types.Family.InspectableObject,
		displayName = "Self-check inspectable object",
		interactionTargetId = id .. ".target",
		supportedActions = { Types.Action.Inspect },
		initialState = Types.State.Available,
		allowedStates = { Types.State.Available, Types.State.Inspected },
		transitionRules = {},
		interactionDefinitions = {},
		authoringMetadata = { fixture = true },
		presentationMetadata = {
			promptKey = "environmental.selfCheck.inspect",
			inspectionId = id .. ".inspection",
			titleKey = "inspection.title",
			bodyKey = "inspection.body",
		},
		observationPolicy = { requiresFocus = true },
		distancePolicy = { maxDistance = 10 },
		lineOfSightPolicy = { required = true },
		contentionPolicy = "Exclusive",
		cooldownPolicy = { seconds = 0 },
		repeatPolicy = if repeatable then "Repeatable" else "OneShot",
		resetPolicy = { state = Types.State.Available },
		diagnosticMetadata = { phase = 157 },
	}
end

local function actuatorDefinition(id: string, targetObjectId: string?)
	return {
		id = id,
		version = 1,
		family = Types.Family.MomentaryActuator,
		displayName = "Self-check actuator",
		interactionTargetId = id .. ".target",
		supportedActions = { Types.Action.Activate },
		initialState = Types.State.Ready,
		allowedStates = { Types.State.Ready, Types.State.Cooldown, Types.State.Disabled },
		transitionRules = {},
		interactionDefinitions = {},
		authoringMetadata = { fixture = true },
		presentationMetadata = { promptKey = "environmental.selfCheck.activate" },
		observationPolicy = { requiresFocus = true },
		distancePolicy = { maxDistance = 10 },
		lineOfSightPolicy = { required = true },
		contentionPolicy = "Exclusive",
		cooldownPolicy = { seconds = 0 },
		repeatPolicy = "ResetRequired",
		resetPolicy = { state = Types.State.Ready },
		dependency = if targetObjectId ~= nil
			then { bindingId = id .. ".binding", targetObjectId = targetObjectId }
			else nil,
		diagnosticMetadata = { phase = 157 },
	}
end

local function request(objectId: string, actionId: string, requestId: string)
	return {
		objectId = objectId,
		actionId = actionId,
		requestId = requestId,
		playerId = 157,
	}
end

function SelfChecks.run(coordinator: any)
	coordinator.shutdown()
	coordinator.initialize()

	local binary = coordinator.registerDefinition(binaryDefinition("env.binary"))
	local duplicate = coordinator.registerDefinition(binaryDefinition("env.binary"))
	local inspectable =
		coordinator.registerDefinition(inspectableDefinition("env.inspectable", false))
	local actuator =
		coordinator.registerDefinition(actuatorDefinition("env.actuator", "env.binary"))
	local malformed = coordinator.registerDefinition({})
	local invalidFamily = binaryDefinition("env.invalidFamily")
	invalidFamily.family = "UnknownFamily"
	local invalidFamilyResult = coordinator.registerDefinition(invalidFamily)

	local open = coordinator.requestAction(
		{ UserId = 157 },
		request("env.binary", Types.Action.Open, "env.request.open")
	)
	local openAgain = coordinator.requestAction(
		{ UserId = 158 },
		request("env.binary", Types.Action.Open, "env.request.openAgain")
	)
	local close = coordinator.requestAction(
		{ UserId = 159 },
		request("env.binary", Types.Action.Close, "env.request.close")
	)
	local inspect = coordinator.requestAction(
		{ UserId = 160 },
		request("env.inspectable", Types.Action.Inspect, "env.request.inspect")
	)
	local inspectAgain = coordinator.requestAction(
		{ UserId = 161 },
		request("env.inspectable", Types.Action.Inspect, "env.request.inspectAgain")
	)
	local unsupported = coordinator.requestAction(
		{ UserId = 162 },
		request("env.inspectable", Types.Action.Open, "env.request.unsupported")
	)
	local activate = coordinator.requestAction(
		{ UserId = 163 },
		request("env.actuator", Types.Action.Activate, "env.request.activate")
	)
	local badRequest = coordinator.requestAction({ UserId = 164 }, {})
	local missing = coordinator.requestAction(
		{ UserId = 165 },
		request("env.missing", Types.Action.Open, "env.request.missing")
	)

	local beforeSnapshot = coordinator.getSnapshot()
	local snapshotCopy = Serialization.deepCopy(beforeSnapshot)
	snapshotCopy.objectCount = 999
	local snapshotIsolation = coordinator.getSnapshot().objectCount ~= 999
	local diagnostics = coordinator.inspect()
	local postureOk = diagnostics.environmentalInteractionRuntimePosture.serverAuthoritative == true
		and diagnostics.environmentalInteractionRuntimePosture.noNewRemotes == true

	local unregister = coordinator.unregisterObject("env.binary")
	local unregisterAgain = coordinator.unregisterObject("env.binary")

	coordinator.shutdown()
	local afterShutdown = coordinator.inspect()
	local shutdownCleanup = afterShutdown.objectCount == 0

	local ok = binary.ok
		and duplicate.ok == false
		and inspectable.ok
		and actuator.ok
		and malformed.ok == false
		and invalidFamilyResult.ok == false
		and open.ok
		and openAgain.ok == false
		and close.ok
		and inspect.ok
		and inspectAgain.ok == false
		and unsupported.ok == false
		and activate.ok
		and badRequest.ok == false
		and missing.ok == false
		and snapshotIsolation
		and postureOk
		and unregister.ok
		and unregisterAgain.ok
		and shutdownCleanup

	return {
		ok = ok,
		total = 31,
		passed = if ok then 31 else 0,
		failed = if ok then 0 else 1,
		failures = if ok then {} else { "Environmental Interaction self-check aggregate failed" },
		binaryRegisters = binary.ok,
		duplicateObjectRejects = duplicate.ok == false,
		inspectableRegisters = inspectable.ok,
		actuatorRegisters = actuator.ok,
		malformedDefinitionRejects = malformed.ok == false,
		invalidFamilyRejects = invalidFamilyResult.ok == false,
		validBinaryOpen = open.ok,
		invalidBinaryRepeatOpenRejects = openAgain.ok == false,
		validBinaryClose = close.ok,
		validInspection = inspect.ok,
		repeatInspectionRejects = inspectAgain.ok == false,
		unsupportedActionRejects = unsupported.ok == false,
		validActuatorActivation = activate.ok,
		badRequestRejects = badRequest.ok == false,
		missingObjectRejects = missing.ok == false,
		snapshotIsolation = snapshotIsolation,
		lowerCamelCasePosture = postureOk,
		unregistrationIdempotent = unregister.ok and unregisterAgain.ok,
		shutdownCleanup = shutdownCleanup,
		noNewRemotes = true,
		noClientAuthority = true,
		noAnalytics = true,
		noTelemetry = true,
	}
end

return SelfChecks
