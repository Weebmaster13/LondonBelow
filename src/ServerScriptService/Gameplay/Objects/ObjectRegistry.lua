--!strict

local ObjectState = require(script.Parent.ObjectState)
local ObjectValidator = require(script.Parent.ObjectValidator)
local Types = require(script.Parent.ObjectTypes)

local ObjectRegistry = {}

type ObjectDefinition = Types.ObjectDefinition

local definitions: { [string]: ObjectDefinition } = {}
local order: { string } = {}
local counters = {
	registered = 0,
	duplicatesRejected = 0,
	invalidRejected = 0,
}

local function cloneDefinition(definition: ObjectDefinition): ObjectDefinition
	return {
		id = definition.id,
		kind = definition.kind,
		ownerSystem = definition.ownerSystem,
		allowedStates = table.clone(definition.allowedStates),
		initialState = definition.initialState,
		interactionPermissions = table.clone(definition.interactionPermissions),
		dependencies = table.clone(definition.dependencies),
		observationsEmitted = table.clone(definition.observationsEmitted),
		directorRequestHooks = table.clone(definition.directorRequestHooks),
		metadata = table.clone(definition.metadata),
	}
end

function ObjectRegistry.register(definition: ObjectDefinition): (boolean, string?)
	local valid, reason = ObjectValidator.validateDefinition(definition)
	if not valid then
		counters.invalidRejected += 1
		return false, reason
	end
	if definitions[definition.id] ~= nil then
		counters.duplicatesRejected += 1
		return false, "duplicate object id"
	end
	definitions[definition.id] = cloneDefinition(definition)
	table.insert(order, definition.id)
	ObjectState.initializeObject(definition)
	counters.registered += 1
	return true, nil
end

function ObjectRegistry.get(id: string): ObjectDefinition?
	local definition = definitions[id]
	return if definition ~= nil then cloneDefinition(definition) else nil
end

function ObjectRegistry.exists(id: string): boolean
	return definitions[id] ~= nil
end

function ObjectRegistry.inspect()
	return {
		count = #order,
		ids = table.clone(order),
		counters = table.clone(counters),
	}
end

function ObjectRegistry.clear()
	table.clear(definitions)
	table.clear(order)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return ObjectRegistry
