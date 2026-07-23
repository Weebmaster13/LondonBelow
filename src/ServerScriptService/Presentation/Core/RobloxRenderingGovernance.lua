--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Governance = {}

function Governance.inspect()
	return Serialization.deepCopy({
		systemName = "Roblox Rendering Capability Foundation",
		providerName = Types.RobloxRenderingProviderName,
		capabilityId = Types.RobloxRenderingCapabilityId,
		platform = Types.RobloxRenderingPlatform,
		authority = "Server",
		owns = {
			"Roblox renderer capability registration",
			"Roblox renderer identity metadata",
			"feature declarations",
			"compatibility negotiation metadata",
			"renderer limits metadata",
			"diagnostics and snapshots",
		},
		doesNotOwn = {
			"GUI creation",
			"rendering execution",
			"camera manipulation",
			"animation playback",
			"sound playback",
			"asset loading",
			"networking",
			"Workspace mutation",
			"persistence",
			"gameplay execution",
			"dialogue execution",
			"client authority",
			"analytics",
			"telemetry",
		},
	})
end

return Governance
