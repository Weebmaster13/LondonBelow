--!strict

local Evidence = require(script.Parent.RenderingRuntimeEvidence)
local Lifecycle = require(script.Parent.RenderingLifecycleManager)
local Metrics = require(script.Parent.RenderingRuntimeMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Producer = {}
local acknowledgements = {}
local order = {}
local nextOrdinal = 0

local lifecycleByKind = {
	Accepted = Types.RenderingRuntimeLifecycleState.Acknowledged,
	Assigned = Types.RenderingRuntimeLifecycleState.Assigned,
	Preparing = Types.RenderingRuntimeLifecycleState.Preparing,
	Ready = Types.RenderingRuntimeLifecycleState.Ready,
	Started = Types.RenderingRuntimeLifecycleState.Ready,
	Completed = Types.RenderingRuntimeLifecycleState.Completed,
	Cancelled = Types.RenderingRuntimeLifecycleState.Cancelled,
	Failed = Types.RenderingRuntimeLifecycleState.Failed,
	Expired = Types.RenderingRuntimeLifecycleState.Expired,
}

function Producer.produce(input: any)
	if #order >= Types.RenderingRuntimeLimits.MaxAcknowledgements then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.LimitExceeded,
			message = "acknowledgement limit exceeded",
		}
	end
	if type(input) ~= "table" then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.ValidationFailure,
			message = "acknowledgement must be a table",
		}
	end
	for _, field in ipairs({
		"renderingAcknowledgementId",
		"renderingSessionId",
		"renderingRequestId",
		"rendererId",
		"kind",
	}) do
		if type(input[field]) ~= "string" or input[field] == "" then
			return {
				ok = false,
				code = Types.RenderingRuntimeFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if acknowledgements[input.renderingAcknowledgementId] ~= nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.DuplicateAcknowledgement,
			message = "duplicate acknowledgement",
		}
	end
	if not Types.isRenderingRuntimeAcknowledgementKind(input.kind) then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.ValidationFailure,
			message = "invalid acknowledgement kind",
		}
	end
	local session = Sessions.get(input.renderingSessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.UnknownSession,
			message = "unknown rendering session",
		}
	end
	if
		session.renderingRequestId ~= input.renderingRequestId
		or session.rendererId ~= input.rendererId
	then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.OwnershipMismatch,
			message = "acknowledgement ownership mismatch",
		}
	end
	local target = lifecycleByKind[input.kind]
	if target ~= session.lifecycleState then
		local transitioned = Lifecycle.transition(input.renderingSessionId, target)
		if not transitioned.ok then
			return transitioned
		end
	end
	nextOrdinal += 1
	local record = {
		renderingAcknowledgementId = input.renderingAcknowledgementId,
		renderingSessionId = input.renderingSessionId,
		renderingRequestId = input.renderingRequestId,
		rendererId = input.rendererId,
		kind = input.kind,
		status = target,
		reason = input.reason or "None",
		ordinal = nextOrdinal,
		runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
	}
	acknowledgements[record.renderingAcknowledgementId] = record
	order[#order + 1] = record.renderingAcknowledgementId
	Metrics.increment("acknowledgements")
	Evidence.record("acknowledgement produced", record)
	return { ok = true, code = "Ok", acknowledgement = Serialization.deepCopy(record) }
end

function Producer.latestForSession(sessionId: string)
	for index = #order, 1, -1 do
		local acknowledgement = acknowledgements[order[index]]
		if acknowledgement.renderingSessionId == sessionId then
			return Serialization.deepCopy(acknowledgement)
		end
	end
	return nil
end

function Producer.inspect()
	local result = {}
	for index, id in ipairs(order) do
		result[index] = Serialization.deepCopy(acknowledgements[id])
	end
	return result
end

function Producer.clear()
	table.clear(acknowledgements)
	table.clear(order)
	nextOrdinal = 0
end

return Producer
