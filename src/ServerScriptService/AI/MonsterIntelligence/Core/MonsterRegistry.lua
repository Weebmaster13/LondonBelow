--!strict
--[[
	Registry for monster intelligence definitions.

	The registry stores abstract monster records only. It does not create NPCs,
	models, animations, sounds, or Workspace instances.
]]

local Config = require(script.Parent.MonsterConfig)
local Validator = require(script.Parent.MonsterValidator)

local MonsterRegistry = {}

local definitions: { [string]: any } = {}
local order: { string } = {}

local function cloneDefinition(definition: any)
	return {
		monsterId = definition.monsterId,
		archetype = definition.archetype,
		displayName = definition.displayName,
		territoryId = definition.territoryId,
		tags = if type(definition.tags) == "table" then table.clone(definition.tags) else {},
	}
end

function MonsterRegistry.register(definition: any): (boolean, string?)
	local valid, reason = Validator.validateDefinition(definition)
	if not valid then
		return false, reason
	end
	if definitions[definition.monsterId] ~= nil then
		return false, "duplicate monster ID"
	end
	if #order >= Config.MaxMonsters then
		return false, "monster registry limit reached"
	end
	definitions[definition.monsterId] = cloneDefinition(definition)
	table.insert(order, definition.monsterId)
	return true, nil
end

function MonsterRegistry.exists(monsterId: string): boolean
	return definitions[monsterId] ~= nil
end

function MonsterRegistry.get(monsterId: string): any?
	local definition = definitions[monsterId]
	return if definition ~= nil then cloneDefinition(definition) else nil
end

function MonsterRegistry.getAll(): { any }
	local result = {}
	for _, monsterId in ipairs(order) do
		local definition = definitions[monsterId]
		if definition ~= nil then
			table.insert(result, cloneDefinition(definition))
		end
	end
	return result
end

function MonsterRegistry.clear()
	table.clear(definitions)
	table.clear(order)
end

function MonsterRegistry.inspect()
	return {
		monsterCount = #order,
		limit = Config.MaxMonsters,
		monsters = MonsterRegistry.getAll(),
	}
end

return MonsterRegistry
