--!strict

local Diagnostics = require(script.Parent.PresentationDiagnostics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		dialogueRuntimePresentationContractSnapshot = Diagnostics.capture(runtime),
	})
end

return Snapshots
