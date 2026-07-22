--!strict

local Evidence = require(script.Parent.EventEvidence)
local Serialization = require(script.Parent.EventSerialization)
local Types = require(script.Parent.EventTypes)
local Validation = require(script.Parent.EventValidation)

local Registry = {}
local definitions: { [string]: any } = {}

function Registry.register(definition: any)
	if #Serialization.sortedKeys(definitions) >= Types.Limits.MaxEventTypes then
		return { ok = false, code = "LimitExceeded", message = "event type limit reached" }
	end
	local ok, code, reason = Validation.eventDefinition(definition)
	if not ok then
		return { ok = false, code = code, message = reason }
	end
	if definitions[definition.eventType] ~= nil then
		return { ok = false, code = "DuplicateEventType", message = "duplicate event type" }
	end
	definitions[definition.eventType] = Serialization.deepCopy(definition)
	Evidence.record("event type registered", { eventType = definition.eventType })
	return { ok = true, code = "Ok", definition = Serialization.deepCopy(definition) }
end

function Registry.get(eventType: string): any?
	local definition = definitions[eventType]
	return if definition == nil then nil else Serialization.deepCopy(definition)
end

function Registry.has(eventType: string): boolean
	return definitions[eventType] ~= nil
end

function Registry.inspect()
	local output = {}
	for _, eventType in ipairs(Serialization.sortedKeys(definitions)) do
		output[eventType] = Serialization.deepCopy(definitions[eventType])
	end
	return table.freeze(output)
end

function Registry.clear()
	table.clear(definitions)
end

return Registry
