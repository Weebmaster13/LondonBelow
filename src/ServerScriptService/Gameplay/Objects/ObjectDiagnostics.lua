--!strict

local ObjectDiagnostics = {}

function ObjectDiagnostics.capture(dependencies: { [string]: any })
	return {
		registry = dependencies.ObjectRegistry.inspect(),
		state = dependencies.ObjectState.inspect(),
		health = {
			healthy = true,
			status = "Ready",
			message = "Object Runtime stores data-only object truth.",
		},
	}
end

return ObjectDiagnostics
