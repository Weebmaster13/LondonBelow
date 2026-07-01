--!strict

local Config = require(script.Parent.GameplayConfig)

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
	local event = table.clone(payload)
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

function GameplayMemory.clear()
	table.clear(events)
	table.clear(counters)
end

return GameplayMemory
