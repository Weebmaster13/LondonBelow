--!strict

local Diagnostics = require(script.Parent.RenderingDiagnostics)
local Types = require(script.Parent.PresentationTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return {
		providerName = Types.RenderingContractSnapshotProviderName,
		presentationRuntimeRenderingContractSnapshot = Diagnostics.copy(
			Diagnostics.capture(runtime)
		),
	}
end

return Snapshots
