--!strict

local Evidence = require(script.Parent.PresentationEvidence)
local Metrics = require(script.Parent.PresentationMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local capability: any? = nil

function Registry.register(definition: any)
	if type(definition) ~= "table" then
		return {
			ok = false,
			code = Types.RuntimeFailureType.ValidationFailure,
			message = "capability must be a table",
		}
	end
	for _, field in ipairs({ "capabilityId", "version", "providerName", "authority" }) do
		if type(definition[field]) ~= "string" or definition[field] == "" then
			return {
				ok = false,
				code = Types.RuntimeFailureType.ValidationFailure,
				message = "invalid field " .. field,
			}
		end
	end
	capability = Serialization.deepCopy(definition)
	Evidence.record(
		"PresentationRuntimeCapabilityRegistered",
		{ capabilityId = definition.capabilityId },
		Types.Limits.MaxEvidence
	)
	return { ok = true, code = "Ok", capability = Serialization.deepCopy(capability) }
end

function Registry.ensureDefault()
	if capability ~= nil then
		return { ok = true, code = "Ok", capability = Serialization.deepCopy(capability) }
	end
	Metrics.increment("consumerRegistrations", 0)
	return Registry.register({
		capabilityId = Types.CapabilityId,
		version = "1.0.0",
		providerName = Types.ProviderName,
		authority = "Server",
		runtimePhase = 176,
		dependencies = {
			"Dialogue Presentation Contract Foundation",
			"Runtime Workflow and Process Orchestration Foundation",
			"Runtime Messaging Integration and Consumer Foundation",
		},
		certificationStatus = "ProductionCandidate",
	})
end

function Registry.inspect()
	return Serialization.deepCopy(capability)
end

function Registry.clear()
	capability = nil
end

return Registry
