--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local RequestRegistry = require(script.Parent.PresentationRequestRegistry)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Registry = {}
local acknowledgements = {}
local order = {}
local nextOrdinal = 0

local statusForKind = {
	[Types.AcknowledgementKind.Accepted] = Types.RequestStatus.Accepted,
	[Types.AcknowledgementKind.Rejected] = Types.RequestStatus.Rejected,
	[Types.AcknowledgementKind.Started] = Types.RequestStatus.Started,
	[Types.AcknowledgementKind.Completed] = Types.RequestStatus.Completed,
	[Types.AcknowledgementKind.Cancelled] = Types.RequestStatus.Cancelled,
	[Types.AcknowledgementKind.Failed] = Types.RequestStatus.Failed,
	[Types.AcknowledgementKind.Expired] = Types.RequestStatus.Expired,
}

function Registry.register(acknowledgement: any)
	if #order >= Types.Limits.MaxAcknowledgements then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "acknowledgement limit exceeded",
		}
	end
	if type(acknowledgement) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.InvalidAcknowledgement,
			message = "acknowledgement must be a table",
		}
	end
	for _, field in ipairs({
		"acknowledgementId",
		"presentationId",
		"executionId",
		"acknowledgementKind",
		"consumerId",
	}) do
		if type(acknowledgement[field]) ~= "string" or acknowledgement[field] == "" then
			return {
				ok = false,
				code = Types.FailureType.InvalidAcknowledgement,
				message = "invalid field " .. field,
			}
		end
	end
	if acknowledgements[acknowledgement.acknowledgementId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateAcknowledgement,
			message = "duplicate acknowledgement",
		}
	end
	if not Types.isAcknowledgementKind(acknowledgement.acknowledgementKind) then
		return {
			ok = false,
			code = Types.FailureType.InvalidAcknowledgement,
			message = "unsupported acknowledgement kind",
		}
	end
	local request = RequestRegistry.get(acknowledgement.presentationId)
	if request == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownPresentation,
			message = "unknown presentation",
		}
	end
	if request.executionId ~= acknowledgement.executionId then
		return {
			ok = false,
			code = Types.FailureType.ExecutionMismatch,
			message = "acknowledgement execution mismatch",
		}
	end
	nextOrdinal += 1
	local record = {
		acknowledgementId = acknowledgement.acknowledgementId,
		presentationId = acknowledgement.presentationId,
		executionId = acknowledgement.executionId,
		acknowledgementKind = acknowledgement.acknowledgementKind,
		consumerId = acknowledgement.consumerId,
		status = statusForKind[acknowledgement.acknowledgementKind],
		reasonCode = acknowledgement.reasonCode or "",
		runtimeMetadata = Serialization.deepCopy(acknowledgement.runtimeMetadata or {}),
		createdOrdinal = nextOrdinal,
	}
	local updated = RequestRegistry.updateStatus(record.presentationId, record.status, {
		acknowledgementId = record.acknowledgementId,
	})
	if not updated.ok then
		return updated
	end
	acknowledgements[record.acknowledgementId] = record
	order[#order + 1] = record.acknowledgementId
	Metrics.increment("acknowledgementsReceived")
	Metrics.increment("acknowledgementsAccepted")
	Evidence.record("acknowledgement accepted", {
		acknowledgementId = record.acknowledgementId,
		presentationId = record.presentationId,
	})
	return { ok = true, code = "Ok", acknowledgement = Serialization.deepCopy(record) }
end

function Registry.get(acknowledgementId: string)
	local acknowledgement = acknowledgements[acknowledgementId]
	return if acknowledgement then Serialization.deepCopy(acknowledgement) else nil
end

function Registry.latestForPresentation(presentationId: string)
	for index = #order, 1, -1 do
		local acknowledgement = acknowledgements[order[index]]
		if acknowledgement.presentationId == presentationId then
			return Serialization.deepCopy(acknowledgement)
		end
	end
	return nil
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
