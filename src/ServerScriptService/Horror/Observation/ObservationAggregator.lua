--!strict
--[[
	Aggregation layer for accepted observations.

	Owns compact counts and high-priority summaries that future systems can read
	without scanning the full timeline.

	Does not own interpretation, player personality, Monster AI, or scare
	selection. Aggregates are facts, not decisions.
]]

local ObservationConfig = require(script.Parent.ObservationConfig)
local Types = require(script.Parent.ObservationTypes)

local ObservationAggregator = {}

type Observation = Types.Observation
type AggregationSnapshot = Types.AggregationSnapshot

local countsById: { [string]: number } = {}
local countsByCategory: { [string]: number } = {}
local countsByUserId: { [number]: number } = {}
local recentHighPriority: { Observation } = {}

local function pushHighPriority(observation: Observation)
	if observation.priority < 50 then
		return
	end

	table.insert(recentHighPriority, observation)

	while #recentHighPriority > ObservationConfig.HighPriorityLimit do
		table.remove(recentHighPriority, 1)
	end
end

function ObservationAggregator.record(observation: Observation)
	countsById[observation.id] = (countsById[observation.id] or 0) + 1
	countsByCategory[observation.category] = (countsByCategory[observation.category] or 0) + 1

	if observation.userId ~= nil then
		countsByUserId[observation.userId] = (countsByUserId[observation.userId] or 0) + 1
	end

	pushHighPriority(observation)
end

function ObservationAggregator.snapshot(): AggregationSnapshot
	return {
		countsById = table.clone(countsById),
		countsByCategory = table.clone(countsByCategory),
		countsByUserId = table.clone(countsByUserId),
		recentHighPriority = table.clone(recentHighPriority),
	}
end

function ObservationAggregator.removePlayer(userId: number)
	countsByUserId[userId] = nil
end

function ObservationAggregator.clear()
	table.clear(countsById)
	table.clear(countsByCategory)
	table.clear(countsByUserId)
	table.clear(recentHighPriority)
end

function ObservationAggregator.validate(): (boolean, string?)
	if #recentHighPriority > ObservationConfig.HighPriorityLimit then
		return false, "ObservationAggregator high priority buffer exceeded limit"
	end

	return true, nil
end

return ObservationAggregator
