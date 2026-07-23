--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Governance = {}

function Governance.inspect()
	return Serialization.deepCopy({
		systemName = "Roblox Rendering Session Runtime",
		providerName = Types.RobloxRenderingSessionProviderName,
		capabilityId = Types.RobloxRenderingSessionCapabilityId,
		platform = Types.RobloxRenderingPlatform,
		authority = "Server",
		owns = {
			"Roblox rendering session metadata",
			"execution-session mapping metadata",
			"renderer ownership metadata",
			"renderer reservation metadata",
			"renderer lifecycle metadata",
			"renderer scheduling metadata",
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
