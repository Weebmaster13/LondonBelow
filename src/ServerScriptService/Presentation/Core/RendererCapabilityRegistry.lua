--!strict

local Evidence = require(script.Parent.RenderingEvidence)
local Metrics = require(script.Parent.RenderingMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local capabilities = {}
local order = {}
local nextOrdinal = 0

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

local function validList(values: any, predicate: (string) -> boolean): boolean
	if type(values) ~= "table" or #values == 0 then
		return false
	end
	for _, value in ipairs(values) do
		if type(value) ~= "string" or not predicate(value) then
			return false
		end
	end
	return true
end

function Registry.register(capability: any)
	if #order >= Types.RenderingContractLimits.MaxRendererCapabilities then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.LimitExceeded,
			message = "renderer capability limit exceeded",
		}
	end
	if type(capability) ~= "table" then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRendererCapability,
			message = "renderer capability must be a table",
		}
	end
	for _, field in ipairs({
		"rendererCapabilityId",
		"rendererType",
		"providerName",
		"version",
		"status",
	}) do
		if not validString(capability[field]) then
			return {
				ok = false,
				code = Types.RenderingContractFailureType.InvalidRendererCapability,
				message = "invalid field " .. field,
			}
		end
	end
	if capabilities[capability.rendererCapabilityId] ~= nil then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.DuplicateRendererCapability,
			message = "duplicate renderer capability",
		}
	end
	if not Types.isRendererCapabilityStatus(capability.status) then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRendererCapability,
			message = "invalid renderer capability status",
		}
	end
	if not validList(capability.supportedRenderingKinds, Types.isRenderingKind) then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRendererCapability,
			message = "invalid supported rendering kinds",
		}
	end
	if
		not validList(
			capability.supportedSynchronizationPolicies,
			Types.isRenderingSynchronizationPolicy
		)
	then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRendererCapability,
			message = "invalid supported synchronization policies",
		}
	end
	local serializable, reason =
		Serialization.validateSerializable(capability.runtimeMetadata or {})
	if not serializable then
		return {
			ok = false,
			code = Types.RenderingContractFailureType.InvalidRendererCapability,
			message = reason,
		}
	end
	nextOrdinal += 1
	local record = {
		rendererCapabilityId = capability.rendererCapabilityId,
		rendererType = capability.rendererType,
		providerName = capability.providerName,
		version = capability.version,
		supportedRenderingKinds = Serialization.deepCopy(capability.supportedRenderingKinds),
		supportedContractVersions = Serialization.deepCopy(
			capability.supportedContractVersions or { "1.0.0" }
		),
		supportedDescriptorVersions = Serialization.deepCopy(
			capability.supportedDescriptorVersions or { "1.0.0" }
		),
		supportedSynchronizationPolicies = Serialization.deepCopy(
			capability.supportedSynchronizationPolicies
		),
		supportedAssetReferenceKinds = Serialization.deepCopy(
			capability.supportedAssetReferenceKinds or {}
		),
		supportedLocalizationMetadata = Serialization.deepCopy(
			capability.supportedLocalizationMetadata or {}
		),
		supportedAccessibilityMetadata = Serialization.deepCopy(
			capability.supportedAccessibilityMetadata or {}
		),
		priority = tonumber(capability.priority) or 0,
		capacityMetadata = Serialization.deepCopy(capability.capacityMetadata or {}),
		registrationOrdinal = nextOrdinal,
		status = capability.status,
		runtimeMetadata = Serialization.deepCopy(capability.runtimeMetadata or {}),
	}
	capabilities[record.rendererCapabilityId] = record
	order[#order + 1] = record.rendererCapabilityId
	Metrics.increment("rendererCapabilitiesRegistered")
	Evidence.record("renderer capability registered", record)
	return { ok = true, code = "Ok", capability = Serialization.deepCopy(record) }
end

function Registry.get(capabilityId: string)
	return Serialization.deepCopy(capabilities[capabilityId])
end

function Registry.inspect()
	local result = {}
	for index, capabilityId in ipairs(order) do
		result[index] = Serialization.deepCopy(capabilities[capabilityId])
	end
	return result
end

function Registry.clear()
	table.clear(capabilities)
	table.clear(order)
	nextOrdinal = 0
end

return Registry
