--!strict
-- Registry for cognitive entities. It stores records only, never Instances.

local Config = require(script.Parent.LivingCognitionConfiguration)
local Serialization = require(script.Parent.LivingCognitionSerialization)
local Validation = require(script.Parent.LivingCognitionValidation)

local Registry = {}

local entities: { [string]: any } = {}
local order: { string } = {}

function Registry.register(definition: any): (boolean, string?)
	local ok, reason = Validation.entity(definition)
	if not ok then
		return false, reason
	end
	if entities[definition.entityId] ~= nil then
		return false, "duplicate entityId"
	end
	if #order >= Config.MaxEntities then
		return false, "cognitive entity limit reached"
	end
	entities[definition.entityId] = Serialization.deepCopy({
		entityId = definition.entityId,
		entityKind = definition.entityKind,
		ownerSystem = definition.ownerSystem,
		tags = if type(definition.tags) == "table" then table.clone(definition.tags) else {},
		registeredAt = os.clock(),
	})
	table.insert(order, definition.entityId)
	return true, nil
end

function Registry.exists(entityId: string): boolean
	return entities[entityId] ~= nil
end

function Registry.get(entityId: string): any?
	local entity = entities[entityId]
	return if entity ~= nil then Serialization.deepCopy(entity) else nil
end

function Registry.clear()
	table.clear(entities)
	table.clear(order)
end

function Registry.inspect()
	return {
		entityCount = #order,
		entityLimit = Config.MaxEntities,
		entities = Serialization.deepCopy(entities),
	}
end

return Registry
