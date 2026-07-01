--!strict

local Config = require(script.Parent.GameplayConfig)
local Copy = require(script.Parent.GameplayCopy)

local GameplayMemory = {}

local events: { any } = {}
local counters: { [string]: number } = {}

local function remember(event: any)
	table.insert(events, event)
	while #events > Config.MemoryLimit do
		table.remove(events, 1)
	end
end

function GameplayMemory.record(kind: string, payload: { [string]: any })
	counters[kind] = (counters[kind] or 0) + 1
	local event = Copy.dictionary(payload)
	event.kind = kind
	event.at = os.clock()
	remember(event)
	return event
end

function GameplayMemory.count(kind: string): number
	return counters[kind] or 0
end

function GameplayMemory.inspect()
	return {
		recentEvents = table.clone(events),
		counters = table.clone(counters),
		eventCount = #events,
		limit = Config.MemoryLimit,
	}
end

function GameplayMemory.serialize()
	return GameplayMemory.inspect()
end

function GameplayMemory.restore(snapshot: any): (boolean, string?)
	GameplayMemory.clear()

	if type(snapshot) ~= "table" then
		return false, "gameplay memory snapshot must be a table"
	end

	if type(snapshot.recentEvents) == "table" then
		for _, event in ipairs(snapshot.recentEvents) do
			remember(Copy.dictionary(event))
		end
	end

	if type(snapshot.counters) == "table" then
		for key, value in pairs(snapshot.counters) do
			if type(key) == "string" and type(value) == "number" then
				counters[key] = value
			end
		end
	end

	return true, nil
end

function GameplayMemory.clear()
	table.clear(events)
	table.clear(counters)
end

return GameplayMemory
