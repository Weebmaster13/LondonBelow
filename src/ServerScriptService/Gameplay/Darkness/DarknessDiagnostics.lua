--!strict

local DarknessDiagnostics = {}

function DarknessDiagnostics.capture(state: any, dependencies: { [string]: any })
	local tracker = dependencies.DarknessExposureTracker.inspect()

	return {
		initialized = state.initialized,
		started = state.started,
		states = tracker.states,
		recentEvents = tracker.recentEvents,
		counters = tracker.counters,
		health = {
			healthy = state.initialized,
			status = if state.started
				then "Running"
				elseif state.initialized then "Ready"
				else "NotInitialized",
			message = "DarknessService owns exposure truth and does not trust clients.",
		},
	}
end

function DarknessDiagnostics.validate(): (boolean, string?)
	return true, nil
end

return DarknessDiagnostics
