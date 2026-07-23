--!strict

local Diagnostics = require(script.Parent.RobloxRenderingDiagnostics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return {
		providerName = Types.RobloxRenderingProviderName,
		robloxRenderingSnapshot = Serialization.deepCopy(Diagnostics.capture(runtime)),
	}
end

return Snapshots
