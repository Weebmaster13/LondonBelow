--!strict
--[[
	Monster knowledge stores believed facts.

	Knowledge may be known, suspected, lost, false, shared, or unknown. It is
	separate from raw memory so future monsters can be wrong in traceable ways.
]]

local Config = require(script.Parent.MonsterConfig)
local Validator = require(script.Parent.MonsterValidator)

local MonsterKnowledge = {}

local knowledge: { [string]: { [string]: any } } = {}
local order: { [string]: { string } } = {}

local function now(): number
	return os.clock()
end

local function trim(monsterId: string)
	local list = order[monsterId]
	local facts = knowledge[monsterId]
	if list == nil or facts == nil then
		return
	end
	while #list > Config.MaxKnowledgePerMonster do
		local removed = table.remove(list, 1)
		if removed ~= nil then
			facts[removed] = nil
		end
	end
end

function MonsterKnowledge.update(entry: any): (boolean, string?)
	local currentTime = now()
	entry.createdAt = entry.createdAt or currentTime
	entry.lastUpdatedAt = currentTime
	entry.confidence = if type(entry.confidence) == "number" then entry.confidence else 0.5
	entry.metadata = if type(entry.metadata) == "table" then table.clone(entry.metadata) else {}

	local ok, reason = Validator.validateKnowledge(entry)
	if not ok then
		return false, reason
	end

	local facts = knowledge[entry.monsterId]
	if facts == nil then
		facts = {}
		knowledge[entry.monsterId] = facts
		order[entry.monsterId] = {}
	end
	if facts[entry.fact] == nil then
		table.insert(order[entry.monsterId], entry.fact)
	end
	facts[entry.fact] = {
		id = entry.id or entry.fact,
		monsterId = entry.monsterId,
		fact = entry.fact,
		state = entry.state,
		confidence = math.clamp(entry.confidence, 0, 1),
		source = entry.source or "Unknown",
		createdAt = entry.createdAt,
		lastUpdatedAt = currentTime,
		metadata = entry.metadata,
	}
	trim(entry.monsterId)
	return true, nil
end

function MonsterKnowledge.get(monsterId: string): { any }
	local result = {}
	local facts = knowledge[monsterId] or {}
	for _, fact in ipairs(order[monsterId] or {}) do
		if facts[fact] ~= nil then
			table.insert(result, table.clone(facts[fact]))
		end
	end
	return result
end

function MonsterKnowledge.count(): number
	local count = 0
	for _, list in pairs(order) do
		count += #list
	end
	return count
end

function MonsterKnowledge.clear()
	table.clear(knowledge)
	table.clear(order)
end

function MonsterKnowledge.inspect()
	local perMonster: { [string]: number } = {}
	for monsterId, list in pairs(order) do
		perMonster[monsterId] = #list
	end
	return {
		knowledgeCount = MonsterKnowledge.count(),
		limitPerMonster = Config.MaxKnowledgePerMonster,
		perMonster = perMonster,
	}
end

return MonsterKnowledge
