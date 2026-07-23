--!strict

local Evidence = require(script.Parent.RenderingRuntimeEvidence)
local Metrics = require(script.Parent.RenderingRuntimeMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Registry = {}
local runtime: any = nil

function Registry.registerDefault()
	if runtime ~= nil then
		return {
			ok = false,
			code = Types.RenderingRuntimeFailureType.DuplicateRuntime,
			message = "rendering runtime already registered",
		}
	end
	runtime = {
		runtimeId = Types.RenderingRuntimeId,
		capabilityId = Types.RenderingRuntimeCapabilityId,
		providerName = Types.RenderingRuntimeProviderName,
		version = "1.0.0",
		authority = "Server",
		domain = "PresentationRendering",
		phase = 179,
		dependencies = {
			"Presentation Rendering Contract Foundation",
			"Presentation Runtime Execution and Session Management",
			"Presentation Runtime Capability Foundation",
			"Runtime Domain Capability Foundation",
			"Workflow Runtime",
			"Messaging Runtime",
		},
		certificationStatus = "ProductionCandidate",
	}
	Metrics.increment("runtimesRegistered")
	Evidence.record("runtime capability registered", runtime)
	return { ok = true, code = "Ok", runtime = Serialization.deepCopy(runtime) }
end

function Registry.inspect()
	return Serialization.deepCopy(runtime)
end

function Registry.clear()
	runtime = nil
end

return Registry
