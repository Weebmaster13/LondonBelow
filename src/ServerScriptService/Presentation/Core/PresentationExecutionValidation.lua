--!strict

local Queue = require(script.Parent.PresentationExecutionQueue)
local Sessions = require(script.Parent.SessionExecutionEngine)

local Validation = {}

function Validation.validate()
	for _, execution in ipairs(Sessions.inspect()) do
		if type(execution.executionSessionId) ~= "string" or execution.executionSessionId == "" then
			return false, "invalid execution identity"
		end
		if
			type(execution.presentationSessionId) ~= "string"
			or execution.presentationSessionId == ""
		then
			return false, "invalid presentation session identity"
		end
	end
	for _, bucket in pairs(Queue.inspect()) do
		for _, executionId in ipairs(bucket) do
			if Sessions.get(executionId) == nil then
				return false, "queue references missing execution"
			end
		end
	end
	return true, nil
end

return Validation
