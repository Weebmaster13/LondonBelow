--!strict

local Serialization = require(script.Parent.GameplayFlowSerialization)

local Snapshots = {}

local history: { any } = {}

function Snapshots.capture(registry: any, state: any, evidence: any, diagnostics: any)
	local stateInspection = state.inspect()
	local snapshot = {
		gameplayFlowRuntimeAvailable = diagnostics.gameplayFlowRuntimePosture.available,
		gameplayFlowRuntimePosture = Serialization.deepCopy(diagnostics.gameplayFlowRuntimePosture),
		activeObjective = stateInspection.activeObjective,
		objectiveCounts = {
			total = registry.count(),
			completed = #stateInspection.completedObjectives,
			failed = #stateInspection.failedObjectives,
			skipped = #stateInspection.skippedObjectives,
		},
		checkpointEligible = stateInspection.checkpointEligible,
		evaluationCount = stateInspection.evaluationCount,
		transitionCount = stateInspection.transitionCount,
		evidenceCount = evidence.count(),
	}
	table.insert(history, Serialization.deepCopy(snapshot))
	if #history > 80 then
		table.remove(history, 1)
	end
	return snapshot
end

function Snapshots.history()
	return Serialization.deepCopy(history)
end

function Snapshots.clear()
	table.clear(history)
end

return Snapshots
