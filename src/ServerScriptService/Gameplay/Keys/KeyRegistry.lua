--!strict

local KeyValidator = require(script.Parent.KeyValidator)
local Copy = require(script.Parent.Parent.Core.GameplayCopy)

local KeyRegistry = {}

local definitions: { [string]: any } = {}
local order: { string } = {}
local counters = {
	registered = 0,
	duplicatesRejected = 0,
	invalidRejected = 0,
	used = 0,
	collected = 0,
}

function KeyRegistry.register(definition: any): (boolean, string?)
	local valid, reason = KeyValidator.validateDefinition(definition)
	if not valid then
		counters.invalidRejected += 1
		return false, reason
	end
	if definitions[definition.id] ~= nil then
		counters.duplicatesRejected += 1
		return false, "duplicate key id"
	end
	definitions[definition.id] = Copy.dictionary(definition)
	table.insert(order, definition.id)
	counters.registered += 1
	return true, nil
end

function KeyRegistry.get(keyId: string)
	local definition = definitions[keyId]
	return if definition ~= nil then Copy.dictionary(definition) else nil
end

function KeyRegistry.recordCollected()
	counters.collected += 1
end

function KeyRegistry.recordUsed()
	counters.used += 1
end

function KeyRegistry.inspect()
	return {
		count = #order,
		ids = table.clone(order),
		counters = table.clone(counters),
	}
end

function KeyRegistry.serialize()
	local definitionsSnapshot = {}

	for id, definition in pairs(definitions) do
		definitionsSnapshot[id] = Copy.dictionary(definition)
	end

	return {
		definitions = definitionsSnapshot,
		order = table.clone(order),
		counters = table.clone(counters),
	}
end

function KeyRegistry.clear()
	table.clear(definitions)
	table.clear(order)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return KeyRegistry
