--!strict

local Serialization = require(script.Parent.CommandSerialization)

local Profiler = {}
local handlerDurations: { [string]: number } = {}
local commandCounts: { [string]: number } = {}
local failureCounts: { [string]: number } = {}
local highestRetryCounts: { [string]: number } = {}
local deepestAncestryChains = 0
local largestBatches = 0

function Profiler.record(command: any, result: any, handlerId: string?)
	local duration = if result.commandResult ~= nil
		then result.commandResult.executionDuration or 0
		else 0
	if handlerId ~= nil then
		handlerDurations[handlerId] = math.max(handlerDurations[handlerId] or 0, duration)
	end
	commandCounts[command.commandType] = (commandCounts[command.commandType] or 0) + 1
	if result.ok == false then
		failureCounts[result.code] = (failureCounts[result.code] or 0) + 1
	end
	highestRetryCounts[command.commandId] = command.retryAttempts or 0
end

function Profiler.recordShape(nestedDepth: number, batchSize: number)
	deepestAncestryChains = math.max(deepestAncestryChains, nestedDepth)
	largestBatches = math.max(largestBatches, batchSize)
end

function Profiler.inspect()
	return Serialization.deepCopy({
		slowestHandlers = handlerDurations,
		hottestCommandTypes = commandCounts,
		mostCommonFailures = failureCounts,
		highestRetryCounts = highestRetryCounts,
		deepestAncestryChains = deepestAncestryChains,
		largestBatches = largestBatches,
	})
end

function Profiler.clear()
	table.clear(handlerDurations)
	table.clear(commandCounts)
	table.clear(failureCounts)
	table.clear(highestRetryCounts)
	deepestAncestryChains = 0
	largestBatches = 0
end

return Profiler
