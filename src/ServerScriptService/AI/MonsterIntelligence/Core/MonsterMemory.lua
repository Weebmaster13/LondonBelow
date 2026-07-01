--!strict
--[[
	Bounded decaying monster memory.

	Memory is what a monster remembers experiencing. It is not absolute truth;
	MonsterKnowledge stores believed facts separately.
]]

local Config = require(script.Parent.MonsterConfig)
local Validator = require(script.Parent.MonsterValidator)

local MonsterMemory = {}

local memories: { [string]: { any } } = {}

local function now(): number
	return os.clock()
end

local function trim(list: { any })
	while #list > Config.MaxMemoryPerMonster do
		table.remove(list, 1)
	end
end

function MonsterMemory.remember(entry: any): (boolean, string?)
	local currentTime = now()
	entry.createdAt = entry.createdAt or currentTime
	entry.lastUpdatedAt = entry.lastUpdatedAt or currentTime
	entry.confidence = if type(entry.confidence) == "number" then entry.confidence else 0.5
	entry.metadata = if type(entry.metadata) == "table" then table.clone(entry.metadata) else {}

	local ok, reason = Validator.validateMemory(entry, currentTime)
	if not ok then
		return false, reason
	end

	local list = memories[entry.monsterId]
	if list == nil then
		list = {}
		memories[entry.monsterId] = list
	end

	table.insert(list, {
		id = entry.id or (entry.kind .. ":" .. tostring(currentTime)),
		monsterId = entry.monsterId,
		kind = entry.kind,
		subjectId = entry.subjectId,
		zoneId = entry.zoneId,
		confidence = math.clamp(entry.confidence, 0, 1),
		createdAt = entry.createdAt,
		lastUpdatedAt = entry.lastUpdatedAt,
		expiresAt = entry.expiresAt,
		metadata = entry.metadata,
	})
	trim(list)
	return true, nil
end

function MonsterMemory.decay(monsterId: string, deltaSeconds: number)
	local list = memories[monsterId]
	if list == nil then
		return
	end
	for index = #list, 1, -1 do
		local memory = list[index]
		memory.confidence =
			math.max(0, memory.confidence - Config.MemoryDecayPerSecond * deltaSeconds)
		if memory.confidence <= 0.01 or (memory.expiresAt ~= nil and memory.expiresAt <= now()) then
			table.remove(list, index)
		end
	end
end

function MonsterMemory.get(monsterId: string): { any }
	local result = {}
	for _, memory in ipairs(memories[monsterId] or {}) do
		table.insert(result, table.clone(memory))
	end
	return result
end

function MonsterMemory.count(): number
	local count = 0
	for _, list in pairs(memories) do
		count += #list
	end
	return count
end

function MonsterMemory.clear()
	table.clear(memories)
end

function MonsterMemory.inspect()
	local perMonster: { [string]: number } = {}
	for monsterId, list in pairs(memories) do
		perMonster[monsterId] = #list
	end
	return {
		memoryCount = MonsterMemory.count(),
		limitPerMonster = Config.MaxMemoryPerMonster,
		perMonster = perMonster,
	}
end

return MonsterMemory
