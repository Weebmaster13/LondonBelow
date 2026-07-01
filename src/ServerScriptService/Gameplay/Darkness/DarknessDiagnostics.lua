--!strict

local DarknessDiagnostics = {}

function DarknessDiagnostics.capture(state: any, dependencies: { [string]: any })
	local tracker = dependencies.DarknessExposureTracker.inspect()

	return {
		initialized = state.initialized,
		started = state.started,
		stateCount = tracker.stateCount,
		states = tracker.states,
		recentEvents = tracker.recentEvents,
		counters = tracker.counters,
		protectedCount = tracker.counters.protected,
		unknownProtectedCount = tracker.counters.unknownProtected,
		puzzleProtectedCount = tracker.counters.puzzleProtected,
		safeRoomProtectedCount = tracker.counters.safeRoomProtected,
		directorRequestCount = tracker.counters.directorRequests,
		directorRequestSuppressedCount = tracker.counters.directorRequestsSuppressed,
		exposureObservationSuppressedCount = tracker.counters.exposureObservationsSuppressed,
		cooldownCounts = {
			directorRequests = tracker.counters.directorRequestsSuppressed,
			exposureObservations = tracker.counters.exposureObservationsSuppressed,
		},
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
