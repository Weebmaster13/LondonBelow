--!strict
--[[
	Bounded chronological storage for accepted observations.

	Owns player, party, chapter, monster, and environment timelines as queryable
	windows over accepted observations.

	Does not own pattern recognition, Director decisions, or analytics export.
	The timeline is run-local memory for intelligent horror decisions.
]]

local ObservationConfig = require(script.Parent.ObservationConfig)
local Types = require(script.Parent.ObservationTypes)

local ObservationTimeline = {}

type Observation = Types.Observation
type TimelineQuery = Types.TimelineQuery

local allTimeline: { Observation } = {}
local playerTimelines: { [number]: { Observation } } = {}
local partyTimeline: { Observation } = {}
local chapterTimeline: { Observation } = {}
local monsterTimeline: { Observation } = {}
local environmentTimeline: { Observation } = {}

local function pushLimited<T>(values: { T }, value: T, limit: number)
	table.insert(values, value)

	while #values > limit do
		table.remove(values, 1)
	end
end

local function pushPlayer(observation: Observation)
	if observation.userId == nil then
		return
	end

	local timeline = playerTimelines[observation.userId]

	if timeline == nil then
		timeline = {}
		playerTimelines[observation.userId] = timeline
	end

	pushLimited(timeline, observation, ObservationConfig.PlayerTimelineLimit)
end

function ObservationTimeline.record(observation: Observation)
	pushLimited(allTimeline, observation, ObservationConfig.TimelineLimit)
	pushPlayer(observation)

	if observation.category == "Social" then
		pushLimited(partyTimeline, observation, ObservationConfig.TimelineLimit)
	elseif observation.category == "Monster" then
		pushLimited(monsterTimeline, observation, ObservationConfig.TimelineLimit)
	elseif observation.category == "Environment" then
		pushLimited(environmentTimeline, observation, ObservationConfig.TimelineLimit)
	end

	pushLimited(chapterTimeline, observation, ObservationConfig.TimelineLimit)
end

function ObservationTimeline.query(query: TimelineQuery): { Observation }
	local source = if query.userId ~= nil then playerTimelines[query.userId] or {} else allTimeline
	local results = {}
	local limit = query.limit or 100

	for index = #source, 1, -1 do
		local observation = source[index]

		if query.since ~= nil and observation.at < query.since then
			break
		end

		if query.untilTime == nil or observation.at <= query.untilTime then
			if query.category == nil or observation.category == query.category then
				table.insert(results, observation)

				if #results >= limit then
					break
				end
			end
		end
	end

	return results
end

function ObservationTimeline.removePlayer(userId: number)
	playerTimelines[userId] = nil
end

function ObservationTimeline.clear()
	table.clear(allTimeline)
	table.clear(playerTimelines)
	table.clear(partyTimeline)
	table.clear(chapterTimeline)
	table.clear(monsterTimeline)
	table.clear(environmentTimeline)
end

function ObservationTimeline.inspect()
	return {
		total = #allTimeline,
		players = table.clone(playerTimelines),
		partyCount = #partyTimeline,
		chapterCount = #chapterTimeline,
		monsterCount = #monsterTimeline,
		environmentCount = #environmentTimeline,
		latest = allTimeline[#allTimeline],
	}
end

function ObservationTimeline.validate(): (boolean, string?)
	if #allTimeline > ObservationConfig.TimelineLimit then
		return false, "ObservationTimeline exceeded global limit"
	end

	return true, nil
end

return ObservationTimeline
