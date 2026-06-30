--!strict
--[[
	Balanced run-local memory windows for Observation Engine.

	Owns immediate, short, medium, long, chapter, and match windows plus compact
	route, room, door, hiding spot, scare, monster, puzzle, lantern, and darkness
	counters.

	Does not own permanent save data. Nothing here is DataStore truth, analytics,
	or client state.
]]

local Types = require(script.Parent.ObservationTypes)

local ObservationMemory = {}

type Observation = Types.Observation

local windows: { [string]: { Observation } } = {
	Immediate = {},
	TenSeconds = {},
	ThirtySeconds = {},
	OneMinute = {},
	FiveMinutes = {},
	TenMinutes = {},
	Chapter = {},
	Match = {},
}

local windowSeconds = {
	Immediate = 0,
	TenSeconds = 10,
	ThirtySeconds = 30,
	OneMinute = 60,
	FiveMinutes = 300,
	TenMinutes = 600,
}

local windowLimits = {
	Immediate = 1,
	TenSeconds = 300,
	ThirtySeconds = 600,
	OneMinute = 1000,
	FiveMinutes = 2000,
	TenMinutes = 3000,
	Chapter = 5000,
	Match = 6000,
}

local function pushLimited<T>(values: { T }, value: T, limit: number)
	table.insert(values, value)

	while #values > limit do
		table.remove(values, 1)
	end
end

local counters = {
	routes = {} :: { [string]: number },
	rooms = {} :: { [string]: number },
	doors = {} :: { [string]: number },
	hidingSpots = {} :: { [string]: number },
	scares = {} :: { [string]: number },
	monsterSightings = {} :: { [string]: number },
	puzzleAttempts = {} :: { [string]: number },
	lanternUsage = {} :: { [number]: number },
	darknessExposure = {} :: { [number]: number },
	soundInvestigations = {} :: { [number]: number },
}

local function trimExpired(currentTime: number)
	for windowName, observations in pairs(windows) do
		if windowName ~= "Chapter" and windowName ~= "Match" then
			local seconds = windowSeconds[windowName] or 0

			for index = #observations, 1, -1 do
				local observation = observations[index]

				if seconds == 0 or observation.at + seconds <= currentTime then
					table.remove(observations, index)
				end
			end
		end
	end
end

local function incrementString(map: { [string]: number }, key: any)
	if type(key) == "string" and key ~= "" then
		map[key] = (map[key] or 0) + 1
	end
end

local function incrementUser(map: { [number]: number }, userId: number?, amount: number)
	if userId ~= nil then
		map[userId] = (map[userId] or 0) + amount
	end
end

function ObservationMemory.record(observation: Observation)
	trimExpired(observation.at)

	for windowName in pairs(windows) do
		if windowName ~= "Immediate" then
			pushLimited(windows[windowName], observation, windowLimits[windowName] or 1000)
		end
	end

	table.clear(windows.Immediate)
	table.insert(windows.Immediate, observation)

	local metadata = observation.metadata
	incrementString(
		counters.routes,
		metadata.routeId or metadata.positionKey or observation.context.roomId
	)
	incrementString(counters.rooms, metadata.roomId or observation.context.roomId)
	incrementString(counters.doors, metadata.doorId)
	incrementString(counters.hidingSpots, metadata.hidingSpotId)
	incrementString(counters.scares, metadata.scareId)
	incrementString(counters.monsterSightings, metadata.monsterId)
	incrementString(counters.puzzleAttempts, metadata.puzzleId)

	if observation.category == "Lantern" then
		incrementUser(counters.lanternUsage, observation.userId, observation.amount)
	end

	if observation.id == "Environment.EnterDarkness" then
		incrementUser(counters.darknessExposure, observation.userId, observation.amount)
	end

	if observation.id == "Camera.LookAtWindow" or observation.id == "Camera.LookAtPortrait" then
		incrementUser(counters.soundInvestigations, observation.userId, 1)
	end
end

function ObservationMemory.clear()
	for _, observations in pairs(windows) do
		table.clear(observations)
	end

	for _, counter in pairs(counters) do
		table.clear(counter)
	end
end

function ObservationMemory.inspect()
	return {
		windowCounts = {
			immediate = #windows.Immediate,
			tenSeconds = #windows.TenSeconds,
			thirtySeconds = #windows.ThirtySeconds,
			oneMinute = #windows.OneMinute,
			fiveMinutes = #windows.FiveMinutes,
			tenMinutes = #windows.TenMinutes,
			chapter = #windows.Chapter,
			match = #windows.Match,
		},
		counters = {
			routes = table.clone(counters.routes),
			rooms = table.clone(counters.rooms),
			doors = table.clone(counters.doors),
			hidingSpots = table.clone(counters.hidingSpots),
			scares = table.clone(counters.scares),
			monsterSightings = table.clone(counters.monsterSightings),
			puzzleAttempts = table.clone(counters.puzzleAttempts),
			lanternUsage = table.clone(counters.lanternUsage),
			darknessExposure = table.clone(counters.darknessExposure),
			soundInvestigations = table.clone(counters.soundInvestigations),
		},
	}
end

function ObservationMemory.validate(): (boolean, string?)
	return true, nil
end

return ObservationMemory
