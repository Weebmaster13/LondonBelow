--!strict

local SimulationDiagnostics = {}

function SimulationDiagnostics.capture(state: any, dependencies: { [string]: any })
	return {
		state = state,
		mode = state.mode,
		enabled = state.mode ~= "Disabled",
		scenarios = dependencies.SimulationRegistry.getAll(),
		recentReports = dependencies.recentReports(),
		runCount = state.runCount,
		failCount = state.failCount,
		warningCount = state.warningCount,
		lastRun = state.lastRun,
		scenarioDurations = state.scenarioDurations,
		traceCount = dependencies.SimulationTraceRecorder.count(),
		traces = dependencies.SimulationTraceRecorder.inspect(),
		cleanupResults = state.cleanupResults,
		memoryCounts = {
			recentReports = state.reportCount,
			traces = dependencies.SimulationTraceRecorder.count(),
		},
	}
end

function SimulationDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.SimulationRegistry.validate()
end

return SimulationDiagnostics
