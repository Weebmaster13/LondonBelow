--!strict

local Interruption = require(script.Parent.DialogueInterruptionManager)
local Nested = require(script.Parent.NestedConversationManager)
local PendingQueue = require(script.Parent.PendingChoiceQueue)
local Registry = require(script.Parent.InteractionSessionRegistry)

local Validation = {}

function Validation.validateRuntime()
	for _, session in ipairs(Registry.inspect()) do
		if type(session.interactionId) ~= "string" or session.interactionId == "" then
			return false, "invalid interaction ownership"
		end
		if type(session.executionId) ~= "string" or session.executionId == "" then
			return false, "invalid execution ownership"
		end
	end
	for _, queued in ipairs(PendingQueue.inspect()) do
		if Registry.get(queued.interactionId) == nil then
			return false, "queued interaction missing session"
		end
	end
	for _, record in ipairs(Interruption.inspect()) do
		if type(record.executionId) ~= "string" or record.executionId == "" then
			return false, "invalid interruption record"
		end
	end
	for _, record in ipairs(Nested.inspect()) do
		if record.depth < 1 then
			return false, "invalid nested hierarchy"
		end
	end
	return true, nil
end

return Validation
