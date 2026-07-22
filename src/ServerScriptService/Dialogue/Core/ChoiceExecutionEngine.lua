--!strict

local Evidence = require(script.Parent.ExecutionEvidence)
local Metrics = require(script.Parent.ExecutionMetrics)
local Types = require(script.Parent.DialogueExecutionTypes)

local Choices = {}

function Choices.resolve(node: any, choiceId: string)
	if node == nil or type(node.choices) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.UnknownChoice,
			message = "node has no choices",
		}
	end
	for _, choice in ipairs(node.choices) do
		if choice.choiceId == choiceId then
			Metrics.increment("choicesSelected")
			Evidence.record("execution choice selected", {
				choiceId = choiceId,
				destinationNodeId = choice.destinationNodeId,
			})
			return { ok = true, code = "Ok", choice = choice }
		end
	end
	return { ok = false, code = Types.FailureType.UnknownChoice, message = "unknown choice" }
end

return Choices
