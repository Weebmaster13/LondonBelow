--!strict
-- Registry for server-owned Monster AI execution records. Stores data only, never Instances.

local Serialization = require(script.Parent.MonsterAISerialization)
local Types = require(script.Parent.MonsterAITypes)
local Validator = require(script.Parent.MonsterAIValidator)

local Registry = {}

local definitions: { [string]: any } = {}
local order: { string } = {}

function Registry.register(definition: any): (boolean, string?)
	local ok, reason = Validator.validateDefinition(definition)
	if not ok then
		return false, reason
	end
	if definitions[definition.monsterId] ~= nil then
		return false, "duplicate monsterId"
	end
	if #order >= Types.Limits.MaxMonsters then
		return false, "monster AI registry limit reached"
	end
	definitions[definition.monsterId] = Serialization.deepCopy({
		monsterId = definition.monsterId,
		archetype = definition.archetype,
		ownerSystem = definition.ownerSystem,
		tags = if type(definition.tags) == "table" then table.clone(definition.tags) else {},
		registeredAt = os.clock(),
	})
	table.insert(order, definition.monsterId)
	return true, nil
end

function Registry.exists(monsterId: string): boolean
	return definitions[monsterId] ~= nil
end

function Registry.get(monsterId: string): any?
	local definition = definitions[monsterId]
	return if definition ~= nil then Serialization.deepCopy(definition) else nil
end

function Registry.clear()
	table.clear(definitions)
	table.clear(order)
end

function Registry.inspect()
	return {
		monsterCount = #order,
		monsterLimit = Types.Limits.MaxMonsters,
		monsters = Serialization.deepCopy(definitions),
	}
end

return Registry
