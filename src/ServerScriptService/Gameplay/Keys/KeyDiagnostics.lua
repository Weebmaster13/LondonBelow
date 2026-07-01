--!strict

local KeyDiagnostics = {}

function KeyDiagnostics.capture(dependencies: { [string]: any })
	local registry = dependencies.KeyRegistry.inspect()
	return {
		keyCount = registry.count,
		ids = registry.ids,
		counters = registry.counters,
		health = {
			healthy = true,
			status = "Ready",
			message = "Key Runtime treats keys as server data.",
		},
	}
end

return KeyDiagnostics
