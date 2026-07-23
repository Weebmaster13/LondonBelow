--!strict

local Consumers = require(script.Parent.PresentationConsumerRegistry)
local Queue = require(script.Parent.PresentationQueue)
local Sessions = require(script.Parent.PresentationSessionRegistry)

local Validation = {}

function Validation.validate()
	for _, session in ipairs(Sessions.inspect()) do
		if
			type(session.presentationSessionId) ~= "string"
			or session.presentationSessionId == ""
		then
			return false, "invalid session identity"
		end
		if type(session.presentationId) ~= "string" or session.presentationId == "" then
			return false, "invalid presentation identity"
		end
		if type(session.executionId) ~= "string" or session.executionId == "" then
			return false, "invalid execution identity"
		end
		if Consumers.get(session.consumerId) == nil then
			return false, "session references missing consumer"
		end
	end
	local queue = Queue.inspect()
	for _, bucket in pairs({ queue.queued, queue.assigned, queue.suspended, queue.cancelled }) do
		for _, sessionId in ipairs(bucket) do
			if Sessions.get(sessionId) == nil then
				return false, "queue references missing session"
			end
		end
	end
	return true, nil
end

return Validation
