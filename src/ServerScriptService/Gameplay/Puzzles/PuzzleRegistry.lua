--!strict

local PuzzleState = require(script.Parent.PuzzleState)
local PuzzleValidator = require(script.Parent.PuzzleValidator)

local PuzzleRegistry = {}

local definitions: { [string]: any } = {}
local order: { string } = {}
local counters = {
	registered = 0,
	duplicatesRejected = 0,
	invalidRejected = 0,
}

function PuzzleRegistry.register(definition: any): (boolean, string?)
	local valid, reason = PuzzleValidator.validateDefinition(definition)
	if not valid then
		counters.invalidRejected += 1
		return false, reason
	end
	if definitions[definition.id] ~= nil then
		counters.duplicatesRejected += 1
		return false, "duplicate puzzle id"
	end
	definitions[definition.id] = table.clone(definition)
	table.insert(order, definition.id)
	PuzzleState.initializePuzzle(definition)
	counters.registered += 1
	return true, nil
end

function PuzzleRegistry.get(id: string)
	local definition = definitions[id]
	return if definition ~= nil then table.clone(definition) else nil
end

function PuzzleRegistry.inspect()
	return {
		count = #order,
		ids = table.clone(order),
		counters = table.clone(counters),
	}
end

function PuzzleRegistry.clear()
	table.clear(definitions)
	table.clear(order)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return PuzzleRegistry
