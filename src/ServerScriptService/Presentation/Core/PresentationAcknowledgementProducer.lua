--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Lifecycle = require(script.Parent.PresentationLifecycleManager)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.PresentationSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Producer = {}
local acknowledgements = {}
local order = {}
local nextOrdinal = 0

local stateForKind = {
	[Types.RuntimeAcknowledgementKind.Accepted] = Types.RuntimeSessionState.Acknowledged,
	[Types.RuntimeAcknowledgementKind.Started] = Types.RuntimeSessionState.Ready,
	[Types.RuntimeAcknowledgementKind.Completed] = Types.RuntimeSessionState.Completed,
	[Types.RuntimeAcknowledgementKind.Cancelled] = Types.RuntimeSessionState.Cancelled,
	[Types.RuntimeAcknowledgementKind.Failed] = Types.RuntimeSessionState.Failed,
	[Types.RuntimeAcknowledgementKind.Expired] = Types.RuntimeSessionState.Expired,
}

function Producer.produce(request: any)
	if #order >= Types.Limits.MaxRuntimeAcknowledgements then
		return {
			ok = false,
			code = Types.RuntimeFailureType.LimitExceeded,
			message = "acknowledgement limit exceeded",
		}
	end
	if type(request) ~= "table" then
		return {
			ok = false,
			code = Types.RuntimeFailureType.ValidationFailure,
			message = "acknowledgement request must be a table",
		}
	end
	for _, field in ipairs({ "acknowledgementId", "presentationSessionId", "acknowledgementKind" }) do
		if type(request[field]) ~= "string" or request[field] == "" then
			return {
				ok = false,
				code = Types.RuntimeFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if acknowledgements[request.acknowledgementId] ~= nil then
		return {
			ok = false,
			code = Types.RuntimeFailureType.DuplicateAcknowledgement,
			message = "duplicate acknowledgement",
		}
	end
	if not Types.isRuntimeAcknowledgementKind(request.acknowledgementKind) then
		return {
			ok = false,
			code = Types.RuntimeFailureType.ValidationFailure,
			message = "invalid acknowledgement kind",
		}
	end
	local session = Sessions.get(request.presentationSessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RuntimeFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	local nextState = stateForKind[request.acknowledgementKind]
	local transitioned = Lifecycle.transition(request.presentationSessionId, nextState)
	if not transitioned.ok then
		return transitioned
	end
	nextOrdinal += 1
	local acknowledgement = {
		acknowledgementId = request.acknowledgementId,
		presentationSessionId = request.presentationSessionId,
		presentationId = session.presentationId,
		executionId = session.executionId,
		acknowledgementKind = request.acknowledgementKind,
		createdOrdinal = nextOrdinal,
		runtimeMetadata = Serialization.deepCopy(request.runtimeMetadata or {}),
	}
	acknowledgements[acknowledgement.acknowledgementId] = acknowledgement
	order[#order + 1] = acknowledgement.acknowledgementId
	Metrics.increment("acknowledgementsProduced")
	Evidence.record(
		"PresentationAcknowledgementProduced",
		acknowledgement,
		Types.Limits.MaxEvidence
	)
	return { ok = true, code = "Ok", acknowledgement = Serialization.deepCopy(acknowledgement) }
end

function Producer.latestForSession(sessionId: string)
	for index = #order, 1, -1 do
		local acknowledgement = acknowledgements[order[index]]
		if acknowledgement.presentationSessionId == sessionId then
			return Serialization.deepCopy(acknowledgement)
		end
	end
	return nil
end

function Producer.inspect()
	local result = {}
	for index, acknowledgementId in ipairs(order) do
		result[index] = Serialization.deepCopy(acknowledgements[acknowledgementId])
	end
	return result
end

function Producer.clear()
	table.clear(acknowledgements)
	table.clear(order)
	nextOrdinal = 0
end

return Producer
