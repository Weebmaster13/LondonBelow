--!strict

local Metrics = require(script.Parent.InteractionMetrics)
local Types = require(script.Parent.DialogueInteractionTypes)

local Validator = {}

function Validator.validateResponse(session: any, response: any)
	if session == nil then
		Metrics.increment("validationFailures")
		return {
			ok = false,
			code = Types.FailureType.UnknownInteraction,
			message = "unknown interaction",
		}
	end
	if session.status ~= Types.InteractionStatus.WaitingForResponse then
		Metrics.increment("validationFailures")
		return {
			ok = false,
			code = Types.FailureType.InvalidInteractionStatus,
			message = "interaction not waiting",
		}
	end
	if session.response ~= nil then
		Metrics.increment("validationFailures")
		return {
			ok = false,
			code = Types.FailureType.DuplicateResponse,
			message = "duplicate response",
		}
	end
	if type(response) ~= "table" or response.kind ~= session.expectedResponse then
		Metrics.increment("validationFailures")
		return {
			ok = false,
			code = Types.FailureType.InvalidResponse,
			message = "unexpected response",
		}
	end
	return { ok = true, code = "Ok" }
end

return Validator
