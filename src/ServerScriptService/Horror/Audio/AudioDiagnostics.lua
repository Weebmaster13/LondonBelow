--!strict

local Selector = require(script.Parent.AudioRequestSelector)

local AudioDiagnostics = {}

function AudioDiagnostics.capture(state: any, dependencies: { [string]: any })
	local stateSnapshot = dependencies.AudioState.inspect()

	return {
		initialized = state.initialized,
		started = state.started,
		observationCount = stateSnapshot.counters.observations,
		requestCount = stateSnapshot.counters.requests,
		approvalCount = stateSnapshot.counters.approved,
		rejectionCount = stateSnapshot.counters.rejected,
		deferredCount = stateSnapshot.counters.deferred,
		policySuppressions = stateSnapshot.counters.policySuppressions,
		safeRoomSuppressions = stateSnapshot.counters.safeRoomSuppressions,
		puzzleSuppressions = stateSnapshot.counters.puzzleSuppressions,
		pressureState = stateSnapshot.pressureState,
		pressureScore = stateSnapshot.pressureScore,
		recentRequests = stateSnapshot.recentDecisions,
		approvals = stateSnapshot.recentDecisions,
		rejections = stateSnapshot.recentSuppressions,
		policySafety = dependencies.WorldDiagnostics.capture().policySafety,
		health = {
			healthy = state.initialized,
			status = if state.started
				then "Running"
				elseif state.initialized then "Ready"
				else "NotInitialized",
			message = "Audio Director approves future audio pressure only.",
		},
	}
end

function AudioDiagnostics.validate(): (boolean, string?)
	return Selector.validate()
end

return AudioDiagnostics
