--!strict

local Diagnostics = require(script.Parent.DialogueDiagnostics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		dialogueRuntimeCapabilitySnapshot = Diagnostics.capture(runtime),
	})
end

return Snapshots
