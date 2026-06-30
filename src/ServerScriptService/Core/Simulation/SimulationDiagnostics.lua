--!strict

local SimulationDiagnostics = {}

function SimulationDiagnostics.capture(state: any, dependencies: { [string]: any })
	return {
		state = state,
		mode = state.mode,
		enabled = state.mode ~= "Disabled",
		scenarios = dependencies.SimulationRegistry.getAll(),
		recentReports = dependencies.recentReports(),
		traces = dependencies.SimulationTraceRecorder.inspect(),
	}
end

function SimulationDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	return dependencies.SimulationRegistry.validate()
end

return SimulationDiagnostics
