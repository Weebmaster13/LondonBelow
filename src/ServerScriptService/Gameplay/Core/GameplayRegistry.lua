--!strict

local Config = require(script.Parent.GameplayConfig)
local Types = require(script.Parent.GameplayTypes)

local GameplayRegistry = {}

type GameplayDefinition = Types.GameplayDefinition

local definitions: { [string]: GameplayDefinition } = {}
local registrationOrder: { string } = {}
local counters = {
	registered = 0,
	duplicatesRejected = 0,
	invalidRejected = 0,
}

local function cloneDefinition(definition: GameplayDefinition): GameplayDefinition
	return {
		id = definition.id,
		kind = definition.kind,
		ownerSystem = definition.ownerSystem,
		description = definition.description,
		dependencies = table.clone(definition.dependencies),
		observations = table.clone(definition.observations),
		directorHooks = table.clone(definition.directorHooks),
		metadata = table.clone(definition.metadata),
	}
end

function GameplayRegistry.validateDefinition(definition: GameplayDefinition): (boolean, string?)
	if type(definition.id) ~= "string" or definition.id == "" then
		return false, "definition id is required"
	end
	if type(definition.kind) ~= "string" or definition.kind == "" then
		return false, "definition kind is required"
	end
	if type(definition.ownerSystem) ~= "string" or definition.ownerSystem == "" then
		return false, "owner system is required"
	end
	if #definition.dependencies > Config.MaxDependenciesPerDefinition then
		return false, "definition has too many dependencies"
	end
	return true, nil
end

function GameplayRegistry.register(definition: GameplayDefinition): (boolean, string?)
	local valid, reason = GameplayRegistry.validateDefinition(definition)
	if not valid then
		counters.invalidRejected += 1
		return false, reason
	end
	if definitions[definition.id] ~= nil then
		counters.duplicatesRejected += 1
		return false, "duplicate gameplay definition id"
	end
	if #registrationOrder >= Config.MaxRegisteredDefinitions then
		counters.invalidRejected += 1
		return false, "gameplay definition registry limit reached"
	end

	definitions[definition.id] = cloneDefinition(definition)
	table.insert(registrationOrder, definition.id)
	counters.registered += 1
	return true, nil
end

function GameplayRegistry.get(id: string): GameplayDefinition?
	local definition = definitions[id]
	return if definition ~= nil then cloneDefinition(definition) else nil
end

function GameplayRegistry.exists(id: string): boolean
	return definitions[id] ~= nil
end

function GameplayRegistry.ids(): { string }
	return table.clone(registrationOrder)
end

function GameplayRegistry.inspect()
	return {
		count = #registrationOrder,
		ids = table.clone(registrationOrder),
		counters = table.clone(counters),
	}
end

function GameplayRegistry.clear()
	table.clear(definitions)
	table.clear(registrationOrder)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return GameplayRegistry
