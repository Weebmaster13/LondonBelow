--!strict

local Diagnostics = require(script.Parent.VisualCompositionDiagnostics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return {
		providerName = Types.RobloxVisualCompositionProviderName,
		robloxVisualCompositionSnapshot = Serialization.deepCopy(Diagnostics.capture(runtime)),
	}
end

return Snapshots
