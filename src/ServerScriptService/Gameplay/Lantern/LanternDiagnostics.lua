--!strict

local LanternDiagnostics = {}

function LanternDiagnostics.capture(state: any, dependencies: { [string]: any })
	local lanternState = dependencies.LanternState.inspect()

	return {
		initialized = state.initialized,
		started = state.started,
		playersTracked = state.playersTracked,
		stateCount = lanternState.stateCount,
		states = lanternState.states,
		recentChanges = lanternState.recentChanges,
		counters = lanternState.counters,
		rejectionCount = lanternState.counters.rejected,
		replayCount = lanternState.counters.replayed,
		directorRequestCount = lanternState.counters.directorRequests,
		directorRequestSuppressedCount = lanternState.counters.directorRequestsSuppressed,
		lowBatterySuppressedCount = lanternState.counters.lowBatterySuppressed,
		overuseSuppressedCount = lanternState.counters.overuseSuppressed,
		cooldownCounts = {
			lowBattery = lanternState.counters.lowBatterySuppressed,
			overuse = lanternState.counters.overuseSuppressed,
			directorRequests = lanternState.counters.directorRequestsSuppressed,
		},
		health = {
			healthy = state.initialized,
			status = if state.started
				then "Running"
				elseif state.initialized then "Ready"
				else "NotInitialized",
			message = "LanternService owns server truth and presentation hooks only.",
		},
	}
end

function LanternDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.LanternValidator.validate()
end

return LanternDiagnostics
