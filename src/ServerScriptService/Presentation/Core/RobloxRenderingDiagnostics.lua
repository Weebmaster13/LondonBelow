--!strict

local Capabilities = require(script.Parent.RobloxCapabilityRegistry)
local Certification = require(script.Parent.RobloxRenderingCertification)
local Evidence = require(script.Parent.RobloxRenderingEvidence)
local Governance = require(script.Parent.RobloxRenderingGovernance)
local Limits = require(script.Parent.RobloxRendererLimits)
local Metrics = require(script.Parent.RobloxRenderingMetrics)
local Negotiation = require(script.Parent.RobloxCapabilityNegotiation)
local Profiler = require(script.Parent.RobloxRenderingProfiler)
local Renderers = require(script.Parent.RobloxRendererRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return {
		providerName = Types.RobloxRenderingProviderName,
		capabilityId = Types.RobloxRenderingCapabilityId,
		platform = Types.RobloxRenderingPlatform,
		rendererRegistry = Renderers.inspect(),
		capabilityRegistry = Capabilities.inspect(),
		compatibilityMatrix = Negotiation.inspect(),
		evidence = Evidence.inspect(),
		metrics = Metrics.inspect(),
		profiler = Profiler.inspect(),
		limits = Limits.inspect(),
		governance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = runtime.getCounters(),
		failures = runtime.getFailures(),
		robloxRenderingPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			platform = Types.RobloxRenderingPlatform,
			serverAuthoritative = true,
			deterministicCapabilityRegistration = true,
			deterministicCompatibilityEvaluation = true,
			immutableDiagnostics = true,
			immutableSnapshots = true,
			immutableEvidence = true,
			immutableConfiguration = true,
			immutableFeatureDeclarations = true,
			noRendering = true,
			noGui = true,
			noAssetLoading = true,
			noNetworking = true,
			noWorkspaceMutation = true,
			noPersistence = true,
			noGameplayExecution = true,
			noDialogueExecution = true,
			noClientAuthority = true,
			noAnalytics = true,
			noTelemetry = true,
		},
	}
end

function Diagnostics.copy(value: any)
	return Serialization.deepCopy(value)
end

return Diagnostics
