--!strict

local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueTypes)

local Budgets = {}

function Budgets.inspect()
	return Serialization.deepCopy({
		conversations = Types.Limits.MaxConversationInstances,
		dialogueDefinitions = Types.Limits.MaxDialogueDefinitions,
		variables = Types.Limits.MaxVariablesPerDialogue,
		participants = Types.Limits.MaxParticipants,
		nodeCount = Types.Limits.MaxNodesPerDialogue,
		evidence = Types.Limits.MaxEvidence,
	})
end

return Budgets
