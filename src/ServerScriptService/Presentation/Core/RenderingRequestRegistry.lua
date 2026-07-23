--!strict

local AccessibilityReferences = require(script.Parent.RenderingAccessibilityReferenceRegistry)
local AssetReferences = require(script.Parent.RenderingAssetReferenceRegistry)
local Evidence = require(script.Parent.RenderingEvidence)
local LocalizationReferences = require(script.Parent.RenderingLocalizationReferenceRegistry)
local Metrics = require(script.Parent.RenderingMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local requests = {}
local order = {}

function Registry.register(request: any)
	if #order >= Types.RenderingContractLimits.MaxRenderingRequests then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.LimitExceeded,
			message = "rendering request limit exceeded",
		}
	end
	if
		type(request) ~= "table"
		or type(request.renderingRequestId) ~= "string"
		or request.renderingRequestId == ""
	then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRenderingRequest,
			message = "invalid rendering request",
		}
	end
	if requests[request.renderingRequestId] ~= nil then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.DuplicateRenderingRequest,
			message = "duplicate rendering request",
		}
	end
	local localization =
		LocalizationReferences.register(request.renderingRequestId, request.localizationReferences)
	if not localization.ok then
		return localization
	end
	local accessibility = AccessibilityReferences.register(
		request.renderingRequestId,
		request.accessibilityReferences
	)
	if not accessibility.ok then
		return accessibility
	end
	local assets = AssetReferences.register(request.renderingRequestId, request.assetReferences)
	if not assets.ok then
		return assets
	end
	local record = Serialization.deepCopy(request)
	record.status = Types.RenderingRequestStatus.Registered
	requests[record.renderingRequestId] = record
	order[#order + 1] = record.renderingRequestId
	Metrics.increment("renderingRequestsCreated")
	Evidence.record("rendering request registered", record)
	return { ok = true, code = "Ok", request = Serialization.deepCopy(record) }
end

function Registry.updateStatus(requestId: string, status: string)
	local request = requests[requestId]
	if request == nil then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.UnknownRenderingRequest,
			message = "unknown rendering request",
		}
	end
	if not Types.isRenderingRequestStatus(status) then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRenderingRequest,
			message = "invalid request status",
		}
	end
	request.status = status
	Evidence.record(
		"rendering request status changed",
		{ renderingRequestId = requestId, status = status }
	)
	return { ok = true, code = "Ok", request = Serialization.deepCopy(request) }
end

function Registry.get(requestId: string)
	return Serialization.deepCopy(requests[requestId])
end

function Registry.inspect()
	local result = {}
	for index, requestId in ipairs(order) do
		result[index] = Serialization.deepCopy(requests[requestId])
	end
	return result
end

function Registry.clear()
	table.clear(requests)
	table.clear(order)
end

return Registry
