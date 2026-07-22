--!strict

local Diagnostics = require(script.Parent.ExecutionDiagnostics)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueExecutionTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		dialogueRuntimeExecutionSnapshot = Diagnostics.capture(runtime),
	})
end

return Snapshots
