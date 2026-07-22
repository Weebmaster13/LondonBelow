--!strict

local Diagnostics = require(script.Parent.DomainDiagnostics)
local Serialization = require(script.Parent.DomainSerialization)
local Types = require(script.Parent.DomainCapabilityTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		runtimeDomainCapabilityFoundationSnapshot = {
			domainCapabilityPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
			diagnostics = Diagnostics.capture(runtime),
		},
	})
end

return Snapshots
