--!strict

local Diagnostics = require(script.Parent.RenderingRuntimeDiagnostics)
local Types = require(script.Parent.PresentationTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return {
		providerName = Types.RenderingRuntimeProviderName,
		presentationRenderingRuntimeSnapshot = Diagnostics.copy(Diagnostics.capture(runtime)),
	}
end

return Snapshots
