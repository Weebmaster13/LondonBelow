--!strict

local Evidence = require(script.Parent.RobloxRenderingEvidence)
local Metrics = require(script.Parent.RobloxRenderingMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local capabilities = {}
local order = {}
local nextOrdinal = 0

function Registry.register(input: any)
	if #order >= Types.RobloxRenderingLimits.MaxCapabilities then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.LimitExceeded,
			message = "capability limit exceeded",
		}
	end
	if type(input) ~= "table" then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = "capability must be a table",
		}
	end
	for _, field in ipairs({ "capabilityId", "feature", "capabilityVersion" }) do
		if type(input[field]) ~= "string" or input[field] == "" then
			return {
				ok = false,
				code = Types.RobloxRenderingFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	if capabilities[input.capabilityId] ~= nil then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.DuplicateCapability,
			message = "duplicate capability",
		}
	end
	if not Types.isRobloxRenderingFeature(input.feature) then
		return {
			ok = false,
			code = Types.RobloxRenderingFailureType.ValidationFailure,
			message = "unsupported feature",
		}
	end
	nextOrdinal += 1
	local capability = {
		capabilityId = input.capabilityId,
		feature = input.feature,
		capabilityVersion = input.capabilityVersion,
		enabled = input.enabled ~= false,
		registrationOrdinal = nextOrdinal,
		runtimeMetadata = Serialization.deepCopy(input.runtimeMetadata or {}),
	}
	capabilities[capability.capabilityId] = capability
	order[#order + 1] = capability.capabilityId
	Metrics.increment("registeredCapabilities")
	Evidence.record("capability registered", capability)
	return { ok = true, code = "Ok", capability = Serialization.deepCopy(capability) }
end

function Registry.supports(feature: string): boolean
	for _, id in ipairs(order) do
		local capability = capabilities[id]
		if capability.feature == feature and capability.enabled then
			return true
		end
	end
	return false
end

function Registry.inspect()
	local result = {}
	for index, id in ipairs(order) do
		result[index] = Serialization.deepCopy(capabilities[id])
	end
	return result
end

function Registry.clear()
	table.clear(capabilities)
	table.clear(order)
	nextOrdinal = 0
end

return Registry
