--!strict

local DescriptorValidator = require(script.Parent.RenderingDescriptorValidator)
local Evidence = require(script.Parent.RenderingEvidence)
local Metrics = require(script.Parent.RenderingMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Builder = {}
local nextOrdinal = 0

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

function Builder.build(input: any)
	if type(input) ~= "table" then
		Metrics.increment("renderingRequestsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRenderingRequest,
			message = "rendering request input must be a table",
		}
	end
	for _, field in ipairs({
		"renderingRequestId",
		"executionSessionId",
		"presentationSessionId",
		"presentationId",
		"consumerId",
		"renderingKind",
	}) do
		if not validString(input[field]) then
			Metrics.increment("renderingRequestsRejected")
			return {
				ok = false,
				code = Types.RenderingContractFailureType.InvalidRenderingRequest,
				message = "invalid field " .. field,
			}
		end
	end
	if not Types.isRenderingKind(input.renderingKind) then
		Metrics.increment("renderingRequestsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRenderingKind,
			message = "invalid rendering kind",
		}
	end
	local policy = input.synchronizationPolicy or Types.RenderingSynchronizationPolicy.NoWait
	if not Types.isRenderingSynchronizationPolicy(policy) then
		Metrics.increment("renderingRequestsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidSynchronizationPolicy,
			message = "invalid synchronization policy",
		}
	end
	local descriptorOk, descriptorReason =
		DescriptorValidator.validate(input.descriptor or {}, input.renderingKind)
	if not descriptorOk then
		Metrics.increment("descriptorValidationFailures")
		Metrics.increment("renderingRequestsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidDescriptor,
			message = descriptorReason,
		}
	end
	local serializable, reason = Serialization.validateSerializable(input.runtimeMetadata or {})
	if not serializable then
		Metrics.increment("renderingRequestsRejected")
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRenderingRequest,
			message = reason,
		}
	end
	nextOrdinal += 1
	local request = {
		renderingRequestId = input.renderingRequestId,
		executionSessionId = input.executionSessionId,
		presentationSessionId = input.presentationSessionId,
		presentationId = input.presentationId,
		consumerId = input.consumerId,
		renderingKind = input.renderingKind,
		descriptor = Serialization.deepCopy(input.descriptor or {}),
		synchronizationPolicy = policy,
		localizationReferences = Serialization.deepCopy(input.localizationReferences or {}),
		accessibilityReferences = Serialization.deepCopy(input.accessibilityReferences or {}),
		assetReferences = Serialization.deepCopy(input.assetReferences or {}),
		priority = tonumber(input.priority) or 0,
		creationOrdinal = nextOrdinal,
		runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
		contractVersion = input.contractVersion or "1.0.0",
		status = Types.RenderingRequestStatus.Created,
	}
	Evidence.record("rendering request built", request)
	return { ok = true, code = "Ok", request = request }
end

function Builder.clear()
	nextOrdinal = 0
end

return Builder
