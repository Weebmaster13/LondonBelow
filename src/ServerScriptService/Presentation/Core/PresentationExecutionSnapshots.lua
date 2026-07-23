--!strict

local Diagnostics = require(script.Parent.PresentationExecutionDiagnostics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ExecutionProviderName,
		presentationRuntimeExecutionSnapshot = Diagnostics.capture(runtime),
	})
end

return Snapshots
