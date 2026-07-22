--!strict

local Evidence = require(script.Parent.DialogueEvidence)
local Serialization = require(script.Parent.DialogueSerialization)

local Choices = {}

function Choices.forNode(node: any)
	return Serialization.deepCopy(node.choices or {})
end

function Choices.recordSelection(conversationId: string, choiceId: string)
	Evidence.record("choice selected", {
		conversationId = conversationId,
		choiceId = choiceId,
	})
	return { ok = true, code = "Ok" }
end

return Choices
