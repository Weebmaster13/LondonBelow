--!strict

local Config = require(script.Parent.GameplayConfig)

local GameplayState = {}

local recentEvents: { any } = {}
local counters = {
	eventsRecorded = 0,
	observationsSubmitted = 0,
	directorRequestsSubmitted = 0,
	validationsFailed = 0,
}

local function remember(event: any)
	table.insert(recentEvents, event)
	while #recentEvents > Config.RecentEventLimit do
		table.remove(recentEvents, 1)
	end
end

function GameplayState.recordEvent(event: any)
	counters.eventsRecorded += 1
	remember(event)
end

function GameplayState.increment(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
	end
end

function GameplayState.inspect()
	return {
		recentEvents = table.clone(recentEvents),
		counters = table.clone(counters),
	}
end

function GameplayState.clear()
	table.clear(recentEvents)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return GameplayState
