--!strict

local Configuration = require(script.Parent.RobloxRendererConfiguration)
local Evidence = require(script.Parent.RobloxRenderingEvidence)
local Metrics = require(script.Parent.RobloxRenderingMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local renderers = {}
local order = {}
local nextOrdinal = 0

local allowedFields = {
	rendererId = true,
	platform = true,
	provider = true,
	version = true,
	capabilityVersion = true,
	supportedContractVersions = true,
	supportedRenderingKinds = true,
	supportedDescriptorVersions = true,
	supportedSynchronizationPolicies = true,
	rendererPriority = true,
	status = true,
	configuration = true,
	runtimeMetadata = true,
}

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

local function validateStringArray(
	value: any,
	validator: ((string) -> boolean)?
): (boolean, string?)
	if type(value) ~= "table" then
		return false, "expected array"
	end
	for index, item in ipairs(value) do
		if not validString(item) then
			return false, "invalid string at " .. tostring(index)
		end
		if validator ~= nil and not validator(item) then
			return false, "unsupported value " .. item
		end
	end
	return true, nil
end

function Registry.register(input: any)
	if #order >= Types.RobloxRenderingLimits.MaxRenderers then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.LimitExceeded,
			message = "renderer limit exceeded",
		}
	end
	if type(input) ~= "table" then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = "renderer must be a table",
		}
	end
	for field in pairs(input) do
		if not allowedFields[field] then
			return {
				ok = false,
				code = Types.RobloxRenderingFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	for _, field in ipairs({ "rendererId", "provider", "version", "capabilityVersion" }) do
		if not validString(input[field]) then
			return {
				ok = false,
				code = Types.RobloxRenderingFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if input.platform ~= Types.RobloxRenderingPlatform then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = "platform must be Roblox",
		}
	end
	if renderers[input.rendererId] ~= nil then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.DuplicateRenderer,
			message = "duplicate renderer",
		}
	end
	if input.status ~= nil and not Types.isRobloxRendererStatus(input.status) then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = "invalid renderer status",
		}
	end
	local contractOk, contractReason = validateStringArray(input.supportedContractVersions or {})
	if not contractOk then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = contractReason,
		}
	end
	local descriptorOk, descriptorReason =
		validateStringArray(input.supportedDescriptorVersions or {})
	if not descriptorOk then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = descriptorReason,
		}
	end
	local kindsOk, kindsReason =
		validateStringArray(input.supportedRenderingKinds or {}, Types.isRenderingKind)
	if not kindsOk then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.UnsupportedRenderingKind,
			message = kindsReason,
		}
	end
	local syncOk, syncReason = validateStringArray(
		input.supportedSynchronizationPolicies or {},
		Types.isRenderingSynchronizationPolicy
	)
	if not syncOk then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = syncReason,
		}
	end
	local serializable, reason = Serialization.validateSerializable(input.runtimeMetadata or {})
	if not serializable then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = reason,
		}
	end
	nextOrdinal += 1
	local renderer = {
		rendererId = input.rendererId,
		platform = input.platform,
		provider = input.provider,
		version = input.version,
		capabilityVersion = input.capabilityVersion,
		supportedContractVersions = Serialization.deepCopy(input.supportedContractVersions or {}),
		supportedRenderingKinds = Serialization.deepCopy(input.supportedRenderingKinds or {}),
		supportedDescriptorVersions = Serialization.deepCopy(
			input.supportedDescriptorVersions or {}
		),
		supportedSynchronizationPolicies = Serialization.deepCopy(
			input.supportedSynchronizationPolicies or {}
		),
		rendererPriority = input.rendererPriority or 0,
		status = input.status or Types.RobloxRendererStatus.Registered,
		configuration = Configuration.build(input.configuration),
		runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
		registrationOrdinal = nextOrdinal,
	}
	renderers[renderer.rendererId] = renderer
	order[#order + 1] = renderer.rendererId
	Metrics.increment("registeredRenderers")
	Metrics.increment("configurationLoads")
	Evidence.record("renderer registered", renderer)
	Evidence.record(
		"configuration loaded",
		{ rendererId = renderer.rendererId, configuration = renderer.configuration }
	)
	return { ok = true, code = "Ok", renderer = Serialization.deepCopy(renderer) }
end

function Registry.get(rendererId: string)
	local renderer = renderers[rendererId]
	if renderer == nil then
		return nil
	end
	return Serialization.deepCopy(renderer)
end

function Registry.inspect()
	local result = {}
	for index, id in ipairs(order) do
		result[index] = Serialization.deepCopy(renderers[id])
	end
	return result
end

function Registry.clear()
	table.clear(renderers)
	table.clear(order)
	nextOrdinal = 0
end

return Registry
