--!strict

local PuzzleState = {}
local Copy = require(script.Parent.Parent.Core.GameplayCopy)

local statuses: { [string]: any } = {}
local recentEvents: { any } = {}
local counters = {
	started = 0,
	nodeCompleted = 0,
	wrongInput = 0,
	hintRequested = 0,
	hintShown = 0,
	completed = 0,
	failed = 0,
	rejected = 0,
}

local function remember(event: any)
	table.insert(recentEvents, event)
	while #recentEvents > 140 do
		table.remove(recentEvents, 1)
	end
end

function PuzzleState.initializePuzzle(definition: any)
	statuses[definition.id] = {
		id = definition.id,
		started = false,
		completed = false,
		failed = false,
		completedNodes = {},
		hintsShown = 0,
		attempts = 0,
	}
end

function PuzzleState.get(id: string)
	local status = statuses[id]
	return if status ~= nil then Copy.dictionary(status) else nil
end

function PuzzleState.start(id: string)
	local status = statuses[id]
	if status == nil then
		return nil
	end
	status.started = true
	counters.started += 1
	remember({ at = os.clock(), puzzleId = id, kind = "Started" })
	return Copy.dictionary(status)
end

function PuzzleState.completeNode(id: string, nodeId: string)
	local status = statuses[id]
	if status == nil then
		return nil
	end
	status.completedNodes[nodeId] = true
	status.attempts += 1
	counters.nodeCompleted += 1
	remember({ at = os.clock(), puzzleId = id, nodeId = nodeId, kind = "NodeCompleted" })
	return Copy.dictionary(status)
end

function PuzzleState.recordWrongInput(id: string)
	local status = statuses[id]
	if status ~= nil then
		status.attempts += 1
	end
	counters.wrongInput += 1
	remember({ at = os.clock(), puzzleId = id, kind = "WrongInput" })
end

function PuzzleState.recordHint(id: string)
	local status = statuses[id]
	if status ~= nil then
		status.hintsShown += 1
	end
	counters.hintShown += 1
	remember({ at = os.clock(), puzzleId = id, kind = "HintShown" })
end

function PuzzleState.recordHintRequest(id: string)
	counters.hintRequested += 1
	remember({ at = os.clock(), puzzleId = id, kind = "HintRequested" })
end

function PuzzleState.complete(id: string)
	local status = statuses[id]
	if status == nil then
		return nil
	end
	status.completed = true
	counters.completed += 1
	remember({ at = os.clock(), puzzleId = id, kind = "Completed" })
	return Copy.dictionary(status)
end

function PuzzleState.fail(id: string, reason: string?)
	local status = statuses[id]
	if status ~= nil then
		status.failed = true
	end
	counters.failed += 1
	remember({ at = os.clock(), puzzleId = id, kind = "Failed", reason = reason })
	return if status ~= nil then Copy.dictionary(status) else nil
end

function PuzzleState.recordRejected()
	counters.rejected += 1
end

function PuzzleState.inspect()
	return {
		statuses = Copy.dictionary(statuses),
		recentEvents = Copy.array(recentEvents),
		counters = table.clone(counters),
	}
end

function PuzzleState.serialize()
	return PuzzleState.inspect()
end

function PuzzleState.clear()
	table.clear(statuses)
	table.clear(recentEvents)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return PuzzleState
