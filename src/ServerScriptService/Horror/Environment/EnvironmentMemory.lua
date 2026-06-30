--!strict

local Config = require(script.Parent.EnvironmentDirectorConfig)

local EnvironmentMemory = {}

local recentReactions: { any } = {}
local recentDecisions: { any } = {}
local suppressedReactions: { any } = {}
local failedReactions: { any } = {}
local reactionCounts: { [string]: number } = {}
local zoneCounts: { [string]: number } = {}
local categoryCounts: { [string]: number } = {}

local function trim(values: { any })
	while #values > Config.MemoryLimit do
		table.remove(values, 1)
	end
end

function EnvironmentMemory.recordDecision(decision: any)
	table.insert(recentDecisions, decision)
	trim(recentDecisions)
end

function EnvironmentMemory.recordReaction(
	reactionId: string,
	category: string,
	zoneId: string,
	at: number
)
	table.insert(recentReactions, {
		reactionId = reactionId,
		category = category,
		zoneId = zoneId,
		at = at,
	})

	reactionCounts[reactionId] = (reactionCounts[reactionId] or 0) + 1
	zoneCounts[zoneId] = (zoneCounts[zoneId] or 0) + 1
	categoryCounts[category] = (categoryCounts[category] or 0) + 1
	trim(recentReactions)
end

function EnvironmentMemory.recordSuppressed(
	reactionId: string,
	reason: string,
	zoneId: string,
	at: number
)
	table.insert(suppressedReactions, {
		reactionId = reactionId,
		reason = reason,
		zoneId = zoneId,
		at = at,
	})
	trim(suppressedReactions)
end

function EnvironmentMemory.recordFailed(
	reactionId: string,
	reason: string,
	zoneId: string,
	at: number
)
	table.insert(failedReactions, {
		reactionId = reactionId,
		reason = reason,
		zoneId = zoneId,
		at = at,
	})
	trim(failedReactions)
end

function EnvironmentMemory.getRepeatCount(reactionId: string): number
	return reactionCounts[reactionId] or 0
end

function EnvironmentMemory.inspect()
	return {
		recentReactions = table.clone(recentReactions),
		recentDecisions = table.clone(recentDecisions),
		suppressedReactions = table.clone(suppressedReactions),
		failedReactions = table.clone(failedReactions),
		reactionCounts = table.clone(reactionCounts),
		zoneCounts = table.clone(zoneCounts),
		categoryCounts = table.clone(categoryCounts),
	}
end

function EnvironmentMemory.reset()
	table.clear(recentReactions)
	table.clear(recentDecisions)
	table.clear(suppressedReactions)
	table.clear(failedReactions)
	table.clear(reactionCounts)
	table.clear(zoneCounts)
	table.clear(categoryCounts)
end

return EnvironmentMemory
