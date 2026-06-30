--!strict

local EnvironmentDiagnostics = {}

function EnvironmentDiagnostics.capture(state: any, dependencies: { [string]: any })
	return {
		state = state,
		environmentState = dependencies.EnvironmentState.inspect(),
		memory = dependencies.EnvironmentMemory.inspect(),
		zones = dependencies.EnvironmentZoneContext.inspect(),
		executionBridge = dependencies.EnvironmentExecutionBridge.inspect(),
		registryCount = #dependencies.EnvironmentReactionRegistry.getAll(),
		lastSelection = dependencies.lastSelection(),
		health = {
			healthy = state.initialized == true,
			started = state.started == true,
			message = if state.started
				then "Environment Director running"
				else "Environment Director initialized",
		},
	}
end

function EnvironmentDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	local registryOk, registryErr = dependencies.EnvironmentReactionRegistry.validate()

	if not registryOk then
		return false, registryErr
	end

	return true, nil
end

return EnvironmentDiagnostics
