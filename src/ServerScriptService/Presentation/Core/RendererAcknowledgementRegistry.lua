--!strict

local Evidence = require(script.Parent.RenderingEvidence)
local Metrics = require(script.Parent.RenderingMetrics)
local Requests = require(script.Parent.RenderingRequestRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local acknowledgements = {}
local order = {}
local nextOrdinal = 0

local statusByKind = {
	Accepted = Types.RenderingRequestStatus.Accepted,
	Rejected = Types.RenderingRequestStatus.Rejected,
	Assigned = Types.RenderingRequestStatus.PendingRenderer,
	Preparing = Types.RenderingRequestStatus.Started,
	Ready = Types.RenderingRequestStatus.Started,
	Started = Types.RenderingRequestStatus.Started,
	Completed = Types.RenderingRequestStatus.Completed,
	Cancelled = Types.RenderingRequestStatus.Cancelled,
	Failed = Types.RenderingRequestStatus.Failed,
	Expired = Types.RenderingRequestStatus.Expired,
	Closed = Types.RenderingRequestStatus.Closed,
}

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

function Registry.register(acknowledgement: any)
	if #order >= Types.RenderingContractLimits.MaxAcknowledgements then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.LimitExceeded,
			message = "acknowledgement limit exceeded",
		}
	end
	if type(acknowledgement) ~= "table" then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidAcknowledgement,
			message = "acknowledgement must be a table",
		}
	end
	for _, field in ipairs({
		"renderingAcknowledgementId",
		"renderingRequestId",
		"executionSessionId",
		"presentationSessionId",
		"rendererCapabilityId",
		"acknowledgementKind",
	}) do
		if not validString(acknowledgement[field]) then
			return {
				ok = false,
				code = Types.RenderingContractFailureType.InvalidAcknowledgement,
				message = "invalid field " .. field,
			}
		end
	end
	if acknowledgements[acknowledgement.renderingAcknowledgementId] ~= nil then
		Metrics.increment("acknowledgementsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.DuplicateAcknowledgement,
			message = "duplicate acknowledgement",
		}
	end
	if not Types.isRenderingAcknowledgementKind(acknowledgement.acknowledgementKind) then
		Metrics.increment("acknowledgementsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidAcknowledgement,
			message = "invalid acknowledgement kind",
		}
	end
	local request = Requests.get(acknowledgement.renderingRequestId)
	if request == nil then
		Metrics.increment("acknowledgementsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.UnknownRenderingRequest,
			message = "unknown rendering request",
		}
	end
	if
		request.executionSessionId ~= acknowledgement.executionSessionId
		or request.presentationSessionId ~= acknowledgement.presentationSessionId
	then
		Metrics.increment("acknowledgementsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.OwnershipMismatch,
			message = "acknowledgement ownership mismatch",
		}
	end
	local serializable, reason =
		Serialization.validateSerializable(acknowledgement.runtimeMetadata or {})
	if not serializable then
		Metrics.increment("acknowledgementsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidAcknowledgement,
			message = reason,
		}
	end
	nextOrdinal += 1
	local record = {
		renderingAcknowledgementId = acknowledgement.renderingAcknowledgementId,
		renderingRequestId = acknowledgement.renderingRequestId,
		executionSessionId = acknowledgement.executionSessionId,
		presentationSessionId = acknowledgement.presentationSessionId,
		rendererCapabilityId = acknowledgement.rendererCapabilityId,
		acknowledgementKind = acknowledgement.acknowledgementKind,
		status = acknowledgement.status or statusByKind[acknowledgement.acknowledgementKind],
		reasonCode = acknowledgement.reasonCode or "None",
		creationOrdinal = nextOrdinal,
		runtimeMetadata = Serialization.deepCopy(acknowledgement.runtimeMetadata or {}),
	}
	acknowledgements[record.renderingAcknowledgementId] = record
	order[#order + 1] = record.renderingAcknowledgementId
	Requests.updateStatus(record.renderingRequestId, record.status)
	Metrics.increment("acknowledgementsRegistered")
	Evidence.record("acknowledgement registered", record)
	return { ok = true, code = "Ok", acknowledgement = Serialization.deepCopy(record) }
end

function Registry.latestForRequest(requestId: string)
	for index = #order, 1, -1 do
		local acknowledgement = acknowledgements[order[index]]
		if acknowledgement.renderingRequestId == requestId then
			return Serialization.deepCopy(acknowledgement)
		end
	end
	return nil
end

function Registry.get(acknowledgementId: string)
	return Serialization.deepCopy(acknowledgements[acknowledgementId])
end

function Registry.inspect()
	local result = {}
	for index, acknowledgementId in ipairs(order) do
		result[index] = Serialization.deepCopy(acknowledgements[acknowledgementId])
	end
	return result
end

function Registry.clear()
	table.clear(acknowledgements)
	table.clear(order)
	nextOrdinal = 0
end

return Registry
