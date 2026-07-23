--!strict

local Diagnostics = require(script.Parent.RobloxRenderingSessionDiagnostics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return {
		providerName = Types.RobloxRenderingSessionProviderName,
		robloxRenderingSessionSnapshot = Serialization.deepCopy(Diagnostics.capture(runtime)),
	}
end

return Snapshots
