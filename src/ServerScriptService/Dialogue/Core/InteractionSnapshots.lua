--!strict

local Diagnostics = require(script.Parent.InteractionDiagnostics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueInteractionTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		dialogueRuntimeInteractionSnapshot = Diagnostics.capture(runtime),
	})
end

return Snapshots
