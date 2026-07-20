--!strict

local Serialization = require(script.Parent.EnvironmentalSerialization)
local Types = require(script.Parent.EnvironmentalTypes)

local State = {}

local definitions: { [string]: any } = {}
local objectOrder: { string } = {}
local states: { [string]: any } = {}
local bindings: { [string]: any } = {}
local evidence: { any } = {}
local failures: { any } = {}
local snapshots: { any } = {}
local completedRequests: { [string]: any } = {}
local counters = {
	registrations = 0,
	unregistrations = 0,
	transitionAttempts = 0,
	transitionSuccesses = 0,
	transitionRejections = 0,
	handlerFailures = 0,
	rollbackFailures = 0,
	presentationFailures = 0,
	dependencyFailures = 0,
	cycleRejections = 0,
	inspectSuccesses = 0,
	repeatInspectionRejections = 0,
	binaryTransitions = 0,
	cooldownRejections = 0,
	contentionRejections = 0,
	cleanupFailures = 0,
	staleRevisionRejections = 0,
	duplicateCompletions = 0,
	reconciliationFailures = 0,
}

local function trim(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function count(map: { [string]: any }): number
	local total = 0
	for _ in pairs(map) do
		total += 1
	end
	return total
end

function State.exists(objectId: string): boolean
	return definitions[objectId] ~= nil
end

function State.register(definition: any)
	definitions[definition.id] = Serialization.deepCopy(definition)
	states[definition.id] = {
		objectId = definition.id,
		family = definition.family,
		currentState = definition.initialState,
		previousState = nil,
		revision = 1,
		registered = true,
		enabled = definition.enabled ~= false,
		activeSessionId = nil,
		lastAction = nil,
		lastResult = nil,
		lastTransitionReason = nil,
		updatedSequence = 1,
		presentationRevision = 1,
	}
	table.insert(objectOrder, definition.id)
	while #objectOrder > Types.Limits.MaxObjects do
		local removed = table.remove(objectOrder, 1)
		if removed ~= nil then
			definitions[removed] = nil
			states[removed] = nil
		end
	end
	counters.registrations += 1
end

function State.unregister(objectId: string): boolean
	if definitions[objectId] == nil then
		return false
	end
	definitions[objectId] = nil
	states[objectId] = nil
	for bindingId, binding in pairs(bindings) do
		if binding.sourceObjectId == objectId or binding.targetObjectId == objectId then
			bindings[bindingId] = nil
		end
	end
	for index = #objectOrder, 1, -1 do
		if objectOrder[index] == objectId then
			table.remove(objectOrder, index)
		end
	end
	counters.unregistrations += 1
	return true
end

function State.getDefinition(objectId: string): any?
	return Serialization.deepCopy(definitions[objectId])
end

function State.getState(objectId: string): any?
	return Serialization.deepCopy(states[objectId])
end

function State.commit(objectId: string, plan: any, sessionId: string?, result: any)
	local state = states[objectId]
	if state == nil then
		return false
	end
	state.previousState = state.currentState
	state.currentState = plan.nextState
	state.revision += 1
	state.updatedSequence += 1
	state.presentationRevision += 1
	state.activeSessionId = nil
	state.lastAction = plan.actionId
	state.lastResult = Serialization.deepCopy(result)
	state.lastTransitionReason = "Committed"
	if sessionId ~= nil then
		state.lastSessionId = sessionId
	end
	counters.transitionSuccesses += 1
	if state.family == Types.Family.BinaryMechanism then
		counters.binaryTransitions += 1
	elseif state.family == Types.Family.InspectableObject then
		counters.inspectSuccesses += 1
	end
	return true
end

function State.canCommit(
	objectId: string,
	expectedState: string?,
	expectedRevision: number?
): (boolean, string?)
	local state = states[objectId]
	if state == nil then
		return false, Types.ResultCode.EnvironmentObjectNotFound
	end
	if expectedState ~= nil and state.currentState ~= expectedState then
		counters.staleRevisionRejections += 1
		return false, Types.ResultCode.TransitionSuperseded
	end
	if expectedRevision ~= nil and state.revision ~= expectedRevision then
		counters.staleRevisionRejections += 1
		return false, Types.ResultCode.StateRevisionMismatch
	end
	return true, nil
end

function State.commitWithRevision(
	objectId: string,
	plan: any,
	sessionId: string?,
	result: any,
	expectedRevision: number?
): (boolean, string?)
	local ok, reason = State.canCommit(objectId, plan.previousState, expectedRevision)
	if not ok then
		return false, reason
	end
	return State.commit(objectId, plan, sessionId, result), nil
end

function State.getCompletedRequest(requestId: string): any?
	return Serialization.deepCopy(completedRequests[requestId])
end

function State.recordCompletedRequest(requestId: string, completion: any): (boolean, string?)
	if completedRequests[requestId] ~= nil then
		counters.duplicateCompletions += 1
		return false, Types.ResultCode.DuplicateCompletion
	end
	completedRequests[requestId] = Serialization.deepCopy(completion)
	return true, nil
end

function State.recordEvidence(record: any)
	table.insert(evidence, Serialization.deepCopy(record))
	trim(evidence, Types.Limits.MaxEvidence)
end

function State.recordFailure(code: string, detail: any?)
	table.insert(failures, {
		code = code,
		detail = Serialization.deepCopy(detail),
		recordedAt = os.clock(),
	})
	trim(failures, Types.Limits.MaxFailures)
	if code == Types.ResultCode.EnvironmentHandlerFailed then
		counters.handlerFailures += 1
	elseif code == Types.ResultCode.EnvironmentDependencyMissing then
		counters.dependencyFailures += 1
	elseif code == Types.ResultCode.EnvironmentAlreadyInspected then
		counters.repeatInspectionRejections += 1
	elseif
		code == Types.ResultCode.StateRevisionMismatch
		or code == Types.ResultCode.TransitionSuperseded
	then
		counters.staleRevisionRejections += 1
	elseif code == Types.ResultCode.DuplicateCompletion then
		counters.duplicateCompletions += 1
	elseif code == Types.ResultCode.ReconciliationFailed then
		counters.reconciliationFailures += 1
	else
		counters.transitionRejections += 1
	end
end

function State.increment(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
	end
end

function State.addBinding(binding: any): (boolean, string?)
	if bindings[binding.bindingId] ~= nil then
		return false, Types.ResultCode.DuplicateBinding
	end
	if definitions[binding.targetObjectId] == nil then
		return false, Types.ResultCode.EnvironmentDependencyMissing
	end
	bindings[binding.bindingId] = Serialization.deepCopy(binding)
	return true, nil
end

function State.recordSnapshot(snapshot: any)
	table.insert(snapshots, Serialization.deepCopy(snapshot))
	trim(snapshots, Types.Limits.MaxSnapshots)
end

function State.inspect()
	return {
		definitions = Serialization.deepCopy(definitions),
		states = Serialization.deepCopy(states),
		bindings = Serialization.deepCopy(bindings),
		evidence = Serialization.deepCopy(evidence),
		failures = Serialization.deepCopy(failures),
		snapshots = Serialization.deepCopy(snapshots),
		completedRequests = Serialization.deepCopy(completedRequests),
		counters = Serialization.deepCopy(counters),
		counts = {
			objects = count(definitions),
			bindings = count(bindings),
			evidence = #evidence,
			failures = #failures,
			snapshots = #snapshots,
			completedRequests = count(completedRequests),
		},
	}
end

function State.clear()
	table.clear(definitions)
	table.clear(objectOrder)
	table.clear(states)
	table.clear(bindings)
	table.clear(evidence)
	table.clear(failures)
	table.clear(snapshots)
	table.clear(completedRequests)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return State
