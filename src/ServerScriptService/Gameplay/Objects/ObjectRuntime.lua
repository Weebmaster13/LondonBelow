--!strict

local ObjectDiagnostics = require(script.Parent.ObjectDiagnostics)
local ObjectRegistry = require(script.Parent.ObjectRegistry)
local ObjectState = require(script.Parent.ObjectState)
local ObjectValidator = require(script.Parent.ObjectValidator)
local ObservationService =
	require(game:GetService("ServerScriptService").Horror.Observation.ObservationService)

local ObjectRuntime = {}

function ObjectRuntime.initialize() end

function ObjectRuntime.registerObject(definition: any): (boolean, string?)
	return ObjectRegistry.register(definition)
end

function ObjectRuntime.interact(objectId: string)
	local definition = ObjectRegistry.get(objectId)
	if definition == nil then
		ObjectState.recordRejected()
		return false, "unknown object"
	end
	ObjectState.recordInteraction(objectId)
	ObservationService.observe({
		id = "Gameplay.ObjectInteracted",
		source = "ObjectRuntime",
		metadata = {
			objectId = objectId,
			objectKind = definition.kind,
		},
	})
	return true, nil
end

function ObjectRuntime.setState(objectId: string, nextState: string, metadata: { [string]: any }?)
	local definition = ObjectRegistry.get(objectId)
	if definition == nil then
		ObjectState.recordRejected()
		return false, "unknown object", nil
	end
	local valid, reason = ObjectValidator.validateState(definition, nextState)
	if not valid then
		ObjectState.recordRejected()
		return false, reason, nil
	end
	local status = ObjectState.setState(objectId, nextState, metadata)
	ObservationService.observe({
		id = "Gameplay.ObjectStateChanged",
		source = "ObjectRuntime",
		metadata = {
			objectId = objectId,
			objectKind = definition.kind,
			state = nextState,
		},
	})
	return true, nil, status
end

function ObjectRuntime.createExecutionRequest(
	objectId: string,
	executionId: string,
	executionKind: string,
	requestedState: string?
)
	local currentTime = os.clock()
	return {
		executionId = executionId,
		sourceSystem = "ObjectRuntime",
		targetObjectId = objectId,
		executionKind = executionKind,
		requestedState = requestedState,
		priority = 10,
		createdAt = currentTime,
		expiresAt = currentTime + 20,
		payload = {},
		metadata = {
			objectId = objectId,
		},
		tags = { "object", "execution-hook" },
	}
end

function ObjectRuntime.inspect()
	return ObjectDiagnostics.capture({
		ObjectRegistry = ObjectRegistry,
		ObjectState = ObjectState,
	})
end

function ObjectRuntime.serialize()
	return {
		registry = ObjectRegistry.serialize(),
		state = ObjectState.serialize(),
	}
end

function ObjectRuntime.validate(): (boolean, string?)
	return ObjectValidator.validate()
end

function ObjectRuntime.runSelfChecks()
	ObjectRuntime.shutdown()
	local definition = {
		id = "selfcheck.object",
		kind = "Lever",
		ownerSystem = "ObjectRuntime",
		allowedStates = { "Idle", "Pulled" },
		initialState = "Idle",
		interactionPermissions = { Interact = true },
		dependencies = {},
		observationsEmitted = { "Gameplay.ObjectInteracted" },
		directorRequestHooks = {},
		metadata = {},
	}
	local firstOk = ObjectRuntime.registerObject(definition)
	local duplicateOk = ObjectRuntime.registerObject(definition)
	local invalidStateOk = ObjectRuntime.setState("selfcheck.object", "Impossible", nil)
	ObjectRuntime.shutdown()
	return {
		ok = firstOk == true and duplicateOk == false and invalidStateOk == false,
		duplicateIdsReject = duplicateOk == false,
		invalidStateRejects = invalidStateOk == false,
	}
end

function ObjectRuntime.shutdown()
	ObjectRegistry.clear()
	ObjectState.clear()
end

return ObjectRuntime
