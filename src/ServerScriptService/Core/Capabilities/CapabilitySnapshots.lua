--!strict

local Diagnostics = require(script.Parent.CapabilityDiagnostics)
local Serialization = require(script.Parent.CapabilitySerialization)
local Types = require(script.Parent.CapabilityTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		runtimeCapabilityFrameworkSnapshot = {
			capabilityFrameworkPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
			diagnostics = Diagnostics.capture(runtime),
		},
	})
end

return Snapshots
