--!strict

local Diagnostics = require(script.Parent.RenderingExecutionDiagnostics)
local Types = require(script.Parent.PresentationTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return {
		providerName = Types.RenderingExecutionProviderName,
		presentationRenderingExecutionSnapshot = Diagnostics.copy(Diagnostics.capture(runtime)),
	}
end

return Snapshots
