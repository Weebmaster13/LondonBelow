--!strict

local Evidence = require(script.Parent.DialogueEvidence)
local Serialization = require(script.Parent.DialogueSerialization)

local Conditions = {}

function Conditions.describe(definition: any)
	return Serialization.deepCopy(definition.conditions or {})
end

function Conditions.evaluateMetadataOnly(conditionId: string, context: any?)
	Evidence.record("condition evaluated", {
		conditionId = conditionId,
		context = Serialization.deepCopy(context or {}),
		result = "MetadataOnly",
	})
	return { ok = true, result = "MetadataOnly" }
end

return Conditions
