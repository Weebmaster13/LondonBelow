--!strict

local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)

local Validation = {}

local definitionFields = {
	cancellationPolicy = true,
	category = true,
	completionPolicy = true,
	entryState = true,
	ownerRuntime = true,
	retryPolicy = true,
	states = true,
	timeouts = true,
	transitions = true,
	version = true,
	workflowId = true,
}

local instanceFields = {
	causationId = true,
	correlationId = true,
	instanceId = true,
	metadata = true,
	requester = true,
	variables = true,
	workflowId = true,
}

local unsafeKeys = {
	analytics = true,
	clientauthority = true,
	commandexecutor = true,
	datastore = true,
	fireclient = true,
	fireevent = true,
	fireserver = true,
	http = true,
	instance = true,
	messagingservice = true,
	mutateworkspace = true,
	remote = true,
	telemetry = true,
	workspace = true,
}

local function isId(value: any): boolean
	return type(value) == "string" and value:match("^[%w%.:%-_]+$") ~= nil and #value <= 128
end

local function boundedString(value: any): boolean
	return type(value) == "string" and #value > 0 and #value <= Types.Limits.MaxStringLength
end

local function isList(value: any): boolean
	if type(value) ~= "table" then
		return false
	end
	local count = 0
	for key in pairs(value) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
			return false
		end
		count += 1
	end
	return count == #value
end

local function supported(map: { [string]: string }, value: any): boolean
	for _, item in pairs(map) do
		if value == item then
			return true
		end
	end
	return false
end

local function scanUnsafe(value: any, depth: number, nodes: { count: number }): (boolean, string?)
	if depth > Types.Limits.MaxVariableDepth then
		return false, "payload depth exceeded"
	end
	if type(value) ~= "table" then
		if type(value) == "function" or type(value) == "thread" or type(value) == "userdata" then
			return false, "unsafe value type"
		end
		if type(value) == "string" and #value > Types.Limits.MaxStringLength then
			return false, "string length exceeded"
		end
		return true, nil
	end
	nodes.count += 1
	if nodes.count > Types.Limits.MaxVariableNodes then
		return false, "payload node limit exceeded"
	end
	for key, item in pairs(value) do
		if type(key) == "string" and unsafeKeys[string.lower(key)] then
			return false, "unsafe payload key"
		end
		local ok, reason = scanUnsafe(item, depth + 1, nodes)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function validateStateList(states: any): (boolean, string?)
	if not isList(states) or #states == 0 or #states > Types.Limits.MaxStatesPerWorkflow then
		return false, "states must be a bounded array"
	end
	local seen = {}
	for _, state in ipairs(states) do
		if not boundedString(state) or seen[state] then
			return false, "invalid or duplicate state"
		end
		seen[state] = true
	end
	return true, nil
end

function Validation.definition(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, "workflow definition must be a table"
	end
	for key in pairs(definition) do
		if not definitionFields[key] then
			return false, "unknown workflow definition field: " .. tostring(key)
		end
	end
	for key in pairs(definitionFields) do
		if definition[key] == nil then
			return false, "missing workflow definition field: " .. key
		end
	end
	if not isId(definition.workflowId) or not isId(definition.ownerRuntime) then
		return false, "invalid workflow or owner id"
	end
	if
		not boundedString(definition.version) or not supported(Types.Category, definition.category)
	then
		return false, Types.FailureType.InvalidCategory
	end
	local statesOk, statesReason = validateStateList(definition.states)
	if not statesOk then
		return false, statesReason
	end
	local stateSet = {}
	for _, state in ipairs(definition.states) do
		stateSet[state] = true
	end
	if not stateSet[definition.entryState] then
		return false, "entry state must exist"
	end
	if
		not isList(definition.transitions)
		or #definition.transitions > Types.Limits.MaxTransitionsPerWorkflow
	then
		return false, "transitions must be a bounded array"
	end
	for _, transition in ipairs(definition.transitions) do
		if
			type(transition) ~= "table"
			or not boundedString(transition.fromState)
			or not boundedString(transition.toState)
			or not supported(Types.TransitionSource, transition.source)
			or not stateSet[transition.fromState]
			or not stateSet[transition.toState]
		then
			return false, "invalid transition"
		end
	end
	return scanUnsafe(definition, 0, { count = 0 })
end

function Validation.instance(request: any): (boolean, string?)
	if type(request) ~= "table" then
		return false, "workflow instance request must be a table"
	end
	for key in pairs(request) do
		if not instanceFields[key] then
			return false, "unknown workflow instance field: " .. tostring(key)
		end
	end
	for key in pairs(instanceFields) do
		if request[key] == nil then
			return false, "missing workflow instance field: " .. key
		end
	end
	if not isId(request.instanceId) or not isId(request.workflowId) then
		return false, "invalid instance or workflow id"
	end
	if not boundedString(request.correlationId) or not boundedString(request.causationId) then
		return false, "invalid correlation or causation id"
	end
	if type(request.variables) ~= "table" or type(request.metadata) ~= "table" then
		return false, "variables and metadata must be tables"
	end
	local variableCount = 0
	for _ in pairs(request.variables) do
		variableCount += 1
	end
	if variableCount > Types.Limits.MaxVariables then
		return false, "variable limit exceeded"
	end
	return scanUnsafe(request, 0, { count = 0 })
end

function Validation.copy(value: any): any
	return Serialization.freezeCopy(value)
end

return Validation
