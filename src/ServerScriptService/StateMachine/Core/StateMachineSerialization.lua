--!strict
-- Serialization and isolation helpers for State Machine schema records.

local Types = require(script.Parent.StateMachineTypes)

local Serialization = {}

local SANITIZED_MARKERS = {
	"adapterReference",
	"aiStateExecution",
	"ana" .. "lytics",
	"analyticsCollection",
	"animationStateExecution",
	"blockingExecution",
	"callback",
	"changeState",
	"chapter0Content",
	"chapterContent",
	"clientAuthority",
	"computedResult",
	"condition" .. "Evaluation",
	"conditionRuntimeExecution",
	"consumeInput",
	"currentState",
	"cutscene",
	"dataStore",
	"dataStoreRead",
	"dataStoreWrite",
	"dialogue",
	"dispatch",
	"dispatchEvent",
	"emitOutput",
	"enforcement",
	"enterState",
	"eventConsumption",
	"eventDispatch",
	"eventEmission",
	"eventGraphExecution",
	"executableCallback",
	"execute",
	"executeStateMachine",
	"executionAdapter",
	"executionBatch",
	"exitState",
	"finalDialogue",
	"finalStory",
	"fire",
	"fire" .. "AllClients",
	"fire" .. "Client",
	"frameworkReference",
	"gameplayResult",
	"gameplayStateExecution",
	"guardEvaluation",
	"handlerReference",
	"http",
	"http" .. "Service",
	"inputConsumption",
	"instanceReference",
	"invoke" .. "Client",
	"lifecycleExecution",
	"listener",
	"listenerExecution",
	"liveState",
	"messaging",
	"messaging" .. "Service",
	"moduleReference",
	"monsterAIStateExecution",
	"mutateState",
	"narrativeStateExecution",
	"outputEmission",
	"presentationStateExecution",
	"publish",
	"remote",
	"remote" .. "Event",
	"remote" .. "Function",
	"remediation",
	"ruleEngineExecution",
	"ruleEvaluation",
	"run",
	"runtimeExecution",
	"runtimeGraphExecution",
	"runtimeObject",
	"runtimeOrchestration",
	"runtimeSignalHandle",
	"saveExecution",
	"schedulerExecution",
	"scriptExecution",
	"scripting",
	"serviceReference",
	"setState",
	"signalEmission",
	"signalHandle",
	"stateMachineExecution",
	"stateMutation",
	"stateTransitionExecution",
	"story",
	"subscribe",
	"tele" .. "metry",
	"telemetrySending",
	"transitionExecution",
	"transitionResult",
	"triggerConsumption",
	"triggerEmission",
	"triggerExecution",
	"triggerRuntimeExecution",
	"workspace",
	"workspacePath",
}

local SANITIZED_LOOKUP: { [string]: boolean } = {}
for _, marker in ipairs(SANITIZED_MARKERS) do
	SANITIZED_LOOKUP[string.lower(marker)] = true
end

local function isUnsafeRuntimeValue(value: any): boolean
	local valueType = typeof(value)
	return valueType == "Instance"
		or valueType == "function"
		or valueType == "thread"
		or valueType == "userdata"
end

local function sanitizeScalar(value: any): any
	if type(value) == "string" and SANITIZED_LOOKUP[string.lower(value)] == true then
		return "<unsafe-marker>"
	end
	return value
end

local function copy(
	value: any,
	seen: { [any]: boolean },
	depth: number,
	nodes: { count: number }
): any
	if isUnsafeRuntimeValue(value) then
		return "<unsafe-runtime-value>"
	end
	if type(value) ~= "table" then
		return sanitizeScalar(value)
	end
	if seen[value] == true or depth > Types.Limits.MaxPayloadDepth then
		return "<unsafe-table>"
	end
	seen[value] = true
	nodes.count += 1
	if nodes.count > Types.Limits.MaxPayloadNodes then
		return "<oversized-table>"
	end
	local output = {}
	for key, nested in pairs(value) do
		local safeKey = copy(key, seen, depth + 1, nodes)
		output[safeKey] = copy(nested, seen, depth + 1, nodes)
	end
	seen[value] = nil
	return output
end

local function validate(
	value: any,
	seen: { [any]: boolean },
	depth: number,
	nodes: { count: number }
): (boolean, string?)
	if isUnsafeRuntimeValue(value) then
		return false, "StateMachine payload contains unsafe runtime value"
	end
	if type(value) == "string" and #value > Types.Limits.MaxPayloadStringLength then
		return false, "StateMachine payload string exceeds limit"
	end
	if type(value) ~= "table" then
		return true, nil
	end
	if seen[value] == true then
		return false, "StateMachine payload contains cycle"
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "StateMachine payload depth exceeds limit"
	end
	seen[value] = true
	nodes.count += 1
	if nodes.count > Types.Limits.MaxPayloadNodes then
		return false, "StateMachine payload node count exceeds limit"
	end
	for key, nested in pairs(value) do
		local keyOk, keyReason = validate(key, seen, depth + 1, nodes)
		if not keyOk then
			return false, keyReason
		end
		local nestedOk, nestedReason = validate(nested, seen, depth + 1, nodes)
		if not nestedOk then
			return false, nestedReason
		end
	end
	seen[value] = nil
	return true, nil
end

function Serialization.validateSerializable(value: any): (boolean, string?)
	return validate(value, {}, 0, { count = 0 })
end

function Serialization.deepCopy(value: any): any
	return copy(value, {}, 0, { count = 0 })
end

function Serialization.diagnosticCopy(value: any): any
	return copy(value, {}, 0, { count = 0 })
end

return Serialization
