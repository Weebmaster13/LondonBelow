--!strict
--[[
	Validation helpers for Monster Intelligence.

	Validation rejects malformed ids, invalid confidence values, impossible
	state transitions, unsafe execution requests, and unbounded scoring inputs
	before they can enter diagnostics or decision history.
]]

local Config = require(script.Parent.MonsterConfig)

local MonsterValidator = {}

local VALID_TRANSITIONS: { [string]: { [string]: boolean } } = {
	Dormant = { Observing = true, Interested = true },
	Observing = { Interested = true, Waiting = true, Leaving = true, Dormant = true },
	Interested = { Observing = true, Investigating = true, Waiting = true, Searching = true },
	Investigating = { Searching = true, Waiting = true, Pressuring = true, Leaving = true },
	Waiting = { Observing = true, Investigating = true, Leaving = true },
	Searching = { Observing = true, Investigating = true, Waiting = true, Leaving = true },
	Coordinating = { Investigating = true, Searching = true, Waiting = true, Leaving = true },
	Pressuring = { Waiting = true, Searching = true, Leaving = true },
	Leaving = { Dormant = true, Observing = true },
}

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= 120
end

function MonsterValidator.isValidId(value: any): boolean
	return validId(value)
end

function MonsterValidator.validateConfidence(value: any): (boolean, string?)
	if type(value) ~= "number" or value ~= value then
		return false, "confidence must be a number"
	end
	if value < 0 or value > 1 then
		return false, "confidence must be between 0 and 1"
	end
	return true, nil
end

function MonsterValidator.validateScore(value: any, name: string): (boolean, string?)
	if type(value) ~= "number" or value ~= value then
		return false, name .. " must be a number"
	end
	if value < 0 or value > 100 then
		return false, name .. " must be between 0 and 100"
	end
	return true, nil
end

function MonsterValidator.validateDefinition(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, "monster definition must be a table"
	end
	if not validId(definition.monsterId) then
		return false, "monsterId is required"
	end
	if not validId(definition.archetype) then
		return false, "archetype is required"
	end
	if definition.tags ~= nil and type(definition.tags) ~= "table" then
		return false, "tags must be an array"
	end
	return true, nil
end

function MonsterValidator.validateStateTransition(
	fromState: string,
	toState: string
): (boolean, string?)
	if Config.ValidStates[fromState] ~= true then
		return false, "unknown current monster state"
	end
	if Config.ValidStates[toState] ~= true then
		return false, "unknown next monster state"
	end
	if fromState == toState then
		return true, nil
	end
	if VALID_TRANSITIONS[fromState] == nil or VALID_TRANSITIONS[fromState][toState] ~= true then
		return false, "invalid monster state transition"
	end
	return true, nil
end

function MonsterValidator.validateMemory(entry: any, currentTime: number): (boolean, string?)
	if type(entry) ~= "table" then
		return false, "memory entry must be a table"
	end
	if not validId(entry.monsterId) then
		return false, "memory monsterId is required"
	end
	if Config.ValidMemoryKinds[entry.kind] ~= true then
		return false, "memory kind is not allowed"
	end
	local ok, reason = MonsterValidator.validateConfidence(entry.confidence)
	if not ok then
		return false, reason
	end
	if type(entry.createdAt) == "number" and entry.createdAt > currentTime + 1 then
		return false, "memory timestamp is in the future"
	end
	if type(entry.createdAt) == "number" and currentTime - entry.createdAt < -0.001 then
		return false, "negative memory age"
	end
	return true, nil
end

function MonsterValidator.validateKnowledge(entry: any): (boolean, string?)
	if type(entry) ~= "table" then
		return false, "knowledge entry must be a table"
	end
	if not validId(entry.monsterId) then
		return false, "knowledge monsterId is required"
	end
	if not validId(entry.fact) then
		return false, "knowledge fact is required"
	end
	if Config.ValidKnowledgeStates[entry.state] ~= true then
		return false, "knowledge state is not allowed"
	end
	return MonsterValidator.validateConfidence(entry.confidence)
end

function MonsterValidator.validateInterest(signal: any): (boolean, string?)
	if type(signal) ~= "table" then
		return false, "interest signal must be a table"
	end
	if not validId(signal.monsterId) then
		return false, "interest monsterId is required"
	end
	local scoreOk, scoreReason = MonsterValidator.validateScore(signal.score, "interest")
	if not scoreOk then
		return false, scoreReason
	end
	return MonsterValidator.validateConfidence(signal.confidence)
end

function MonsterValidator.validateIntent(intent: any): (boolean, string?)
	if type(intent) ~= "table" then
		return false, "intent must be a table"
	end
	if not validId(intent.monsterId) then
		return false, "intent monsterId is required"
	end
	if Config.ValidIntentKinds[intent.kind] ~= true then
		return false, "intent kind is not allowed"
	end
	local confidenceOk, confidenceReason = MonsterValidator.validateConfidence(intent.confidence)
	if not confidenceOk then
		return false, confidenceReason
	end
	return MonsterValidator.validateScore(intent.priority, "priority")
end

function MonsterValidator.validateNoUnsafeExecution(request: any): (boolean, string?)
	if type(request) ~= "table" then
		return true, nil
	end
	for _, forbidden in ipairs({
		"workspace",
		"pathfinding",
		"navigation",
		"damage",
		"animation",
		"sound",
		"lighting",
		"remote",
	}) do
		if request[forbidden] ~= nil then
			return false,
				"Monster Intelligence request includes unsafe execution field: " .. forbidden
		end
	end
	return true, nil
end

function MonsterValidator.validate(): (boolean, string?)
	if Config.DecisionMode ~= "IntentOnly" then
		return false, "Monster Intelligence must remain IntentOnly"
	end
	if Config.MaxMonsters <= 0 or Config.MaxMemoryPerMonster <= 0 then
		return false, "Monster Intelligence limits must be positive"
	end
	return true, nil
end

return MonsterValidator
