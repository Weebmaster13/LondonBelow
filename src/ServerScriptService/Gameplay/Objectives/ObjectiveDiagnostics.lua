--!strict

local ObjectiveDiagnostics = {}

function ObjectiveDiagnostics.capture(dependencies: { [string]: any })
	return {
		registry = dependencies.ObjectiveRegistry.inspect(),
		progress = dependencies.ObjectiveState.inspect(),
		health = {
			healthy = true,
			status = "Ready",
			message = "Objective Runtime validates reusable objective progress.",
		},
	}
end

return ObjectiveDiagnostics
