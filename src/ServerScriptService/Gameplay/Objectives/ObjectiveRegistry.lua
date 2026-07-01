--!strict

local ObjectiveState = require(script.Parent.ObjectiveState)
local ObjectiveValidator = require(script.Parent.ObjectiveValidator)

local ObjectiveRegistry = {}

local definitions: { [string]: any } = {}
local order: { string } = {}
local counters = {
	registered = 0,
	duplicatesRejected = 0,
	invalidRejected = 0,
}

function ObjectiveRegistry.register(definition: any): (boolean, string?)
	local valid, reason = ObjectiveValidator.validateDefinition(definition)
	if not valid then
		counters.invalidRejected += 1
		return false, reason
	end
	if definitions[definition.id] ~= nil then
		counters.duplicatesRejected += 1
		return false, "duplicate objective id"
	end
	definitions[definition.id] = table.clone(definition)
	table.insert(order, definition.id)
	ObjectiveState.initializeObjective(definition)
	counters.registered += 1
	return true, nil
end

function ObjectiveRegistry.get(id: string)
	local definition = definitions[id]
	return if definition ~= nil then table.clone(definition) else nil
end

function ObjectiveRegistry.inspect()
	return {
		count = #order,
		ids = table.clone(order),
		counters = table.clone(counters),
	}
end

function ObjectiveRegistry.clear()
	table.clear(definitions)
	table.clear(order)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return ObjectiveRegistry
