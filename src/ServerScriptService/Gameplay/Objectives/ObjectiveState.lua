--!strict

local ObjectiveState = {}

local statuses: { [string]: any } = {}
local recentProgress: { any } = {}
local counters = {
	started = 0,
	progressed = 0,
	completed = 0,
	failed = 0,
	rejected = 0,
}

local function remember(event: any)
	table.insert(recentProgress, event)
	while #recentProgress > 120 do
		table.remove(recentProgress, 1)
	end
end

function ObjectiveState.initializeObjective(definition: any)
	statuses[definition.id] = {
		id = definition.id,
		started = false,
		completed = false,
		failed = false,
		progress = 0,
		currentStep = nil,
	}
end

function ObjectiveState.get(id: string)
	local status = statuses[id]
	return if status ~= nil then table.clone(status) else nil
end

function ObjectiveState.start(id: string)
	local status = statuses[id]
	if status == nil then
		return nil
	end
	status.started = true
	counters.started += 1
	remember({ at = os.clock(), objectiveId = id, kind = "Started" })
	return table.clone(status)
end

function ObjectiveState.progress(id: string, stepId: string, progress: number)
	local status = statuses[id]
	if status == nil then
		return nil
	end
	status.currentStep = stepId
	status.progress = math.clamp(progress, 0, 1)
	counters.progressed += 1
	remember({
		at = os.clock(),
		objectiveId = id,
		kind = "Progressed",
		stepId = stepId,
		progress = status.progress,
	})
	return table.clone(status)
end

function ObjectiveState.complete(id: string)
	local status = statuses[id]
	if status == nil then
		return nil
	end
	status.completed = true
	status.progress = 1
	counters.completed += 1
	remember({ at = os.clock(), objectiveId = id, kind = "Completed" })
	return table.clone(status)
end

function ObjectiveState.fail(id: string, reason: string?)
	local status = statuses[id]
	if status == nil then
		return nil
	end
	status.failed = true
	counters.failed += 1
	remember({ at = os.clock(), objectiveId = id, kind = "Failed", reason = reason })
	return table.clone(status)
end

function ObjectiveState.recordRejected()
	counters.rejected += 1
end

function ObjectiveState.inspect()
	return {
		statuses = table.clone(statuses),
		recentProgress = table.clone(recentProgress),
		counters = table.clone(counters),
	}
end

function ObjectiveState.clear()
	table.clear(statuses)
	table.clear(recentProgress)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return ObjectiveState
