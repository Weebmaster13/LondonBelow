--!strict

local Metrics = require(script.Parent.RenderingMetrics)
local RendererCapabilities = require(script.Parent.RendererCapabilityRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Validator = {}

local function listContains(values: { any }, value: string): boolean
	for _, item in ipairs(values) do
		if item == value then
			return true
		end
	end
	return false
end

function Validator.evaluate(request: any, rendererCapabilityId: string)
	Metrics.increment("compatibilityEvaluations")
	local capability = RendererCapabilities.get(rendererCapabilityId)
	if capability == nil then
		Metrics.increment("incompatibleRendererResults")
		return {
			ok = true,
			result = {
				renderingRequestId = request.renderingRequestId,
				rendererCapabilityId = rendererCapabilityId,
				compatible = false,
				failureCode = Types.RenderingContractFailureType.UnknownRendererCapability,
				unsupportedFields = { "rendererCapabilityId" },
				evaluatedContractVersion = request.contractVersion,
				evaluatedDescriptorVersion = request.descriptor.descriptorVersion or "1.0.0",
				runtimeMetadata = {},
			},
		}
	end
	local unsupported = {}
	if not listContains(capability.supportedRenderingKinds, request.renderingKind) then
		unsupported[#unsupported + 1] = "renderingKind"
	end
	if not listContains(capability.supportedContractVersions, request.contractVersion) then
		unsupported[#unsupported + 1] = "contractVersion"
	end
	if
		not listContains(capability.supportedSynchronizationPolicies, request.synchronizationPolicy)
	then
		unsupported[#unsupported + 1] = "synchronizationPolicy"
	end
	if
		capability.status ~= Types.RendererCapabilityStatus.Available
		and capability.status ~= Types.RendererCapabilityStatus.Registered
	then
		unsupported[#unsupported + 1] = "status"
	end
	local compatible = #unsupported == 0
	if compatible then
		Metrics.increment("compatibleRendererResults")
	else
		Metrics.increment("incompatibleRendererResults")
	end
	return {
		ok = true,
		result = {
			renderingRequestId = request.renderingRequestId,
			rendererCapabilityId = rendererCapabilityId,
			compatible = compatible,
			failureCode = if compatible
				then nil
				else Types.RenderingContractFailureType.RendererIncompatible,
			unsupportedFields = unsupported,
			evaluatedContractVersion = request.contractVersion,
			evaluatedDescriptorVersion = request.descriptor.descriptorVersion or "1.0.0",
			runtimeMetadata = Serialization.deepCopy(capability.runtimeMetadata or {}),
		},
	}
end

return Validator
