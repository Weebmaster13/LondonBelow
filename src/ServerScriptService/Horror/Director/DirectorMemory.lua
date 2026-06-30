--!strict
-- Run-local memory for recent scares, routes, hiding patterns, and decisions.

local HorrorDirectorConfig = require(script.Parent.HorrorDirectorConfig)
local Types = require(script.Parent.HorrorDirectorTypes)

local DirectorMemory = {}

type Observation = Types.Observation
type DirectorDecision = Types.DirectorDecision

local recentScareHistory: { DirectorDecision } = {}
local recentDecisions: { DirectorDecision } = {}
local blockedScares: { { at: number, scareId: string, reason: string } } = {}
local routeCounts: { [string]: number } = {}
local hidingSpotCounts: { [string]: number } = {}
local scareUseCounts: { [string]: number } = {}
local categoryUseCounts: { [string]: number } = {}

local function pushLimited<T>(values: { T }, value: T, limit: number)
	table.insert(values, value)

	while #values > limit do
		table.remove(values, 1)
	end
end

function DirectorMemory.observe(observation: Observation)
	if observation.positionKey ~= nil then
		routeCounts[observation.positionKey] = (routeCounts[observation.positionKey] or 0) + 1
	end

	if observation.metadata ~= nil and type(observation.metadata.hidingSpotId) == "string" then
		local hidingSpotId = observation.metadata.hidingSpotId
		hidingSpotCounts[hidingSpotId] = (hidingSpotCounts[hidingSpotId] or 0) + 1
	end
end

function DirectorMemory.recordDecision(decision: DirectorDecision)
	pushLimited(recentDecisions, decision, HorrorDirectorConfig.RecentDecisionLimit)

	if decision.scareId ~= nil and not decision.silence then
		pushLimited(recentScareHistory, decision, HorrorDirectorConfig.RecentScareMemoryLimit)
		scareUseCounts[decision.scareId] = (scareUseCounts[decision.scareId] or 0) + 1

		if decision.category ~= nil then
			categoryUseCounts[decision.category] = (categoryUseCounts[decision.category] or 0) + 1
		end
	end
end

function DirectorMemory.recordBlocked(scareId: string, reason: string, currentTime: number)
	pushLimited(blockedScares, {
		at = currentTime,
		scareId = scareId,
		reason = reason,
	}, HorrorDirectorConfig.RecentDecisionLimit)
end

function DirectorMemory.getScareUseCount(scareId: string): number
	return scareUseCounts[scareId] or 0
end

function DirectorMemory.wasCategoryUsedRecently(category: string): boolean
	for _, decision in ipairs(recentScareHistory) do
		if decision.category == category then
			return true
		end
	end

	return false
end

function DirectorMemory.inspect()
	return {
		recentScareHistory = table.clone(recentScareHistory),
		recentDecisions = table.clone(recentDecisions),
		blockedScares = table.clone(blockedScares),
		routeCounts = table.clone(routeCounts),
		hidingSpotCounts = table.clone(hidingSpotCounts),
		scareUseCounts = table.clone(scareUseCounts),
		categoryUseCounts = table.clone(categoryUseCounts),
	}
end

function DirectorMemory.validate(): (boolean, string?)
	return true, nil
end

return DirectorMemory
