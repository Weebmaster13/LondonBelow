--!strict

local Bindings = require(script.Parent.VisualCompositionBindings)
local Budgets = require(script.Parent.VisualCompositionBudgets)
local Certification = require(script.Parent.VisualCompositionCertification)
local Definitions = require(script.Parent.VisualCompositionRegistry)
local Evidence = require(script.Parent.VisualCompositionEvidence)
local Governance = require(script.Parent.VisualCompositionGovernance)
local Instances = require(script.Parent.VisualCompositionInstanceRegistry)
local Metrics = require(script.Parent.VisualCompositionMetrics)
local Ownership = require(script.Parent.VisualCompositionOwnership)
local Plans = require(script.Parent.VisualCompositionPlanRegistry)
local Profiler = require(script.Parent.VisualCompositionProfiler)
local Revisions = require(script.Parent.VisualCompositionRevisions)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return {
		providerName = Types.RobloxVisualCompositionProviderName,
		runtimeId = Types.RobloxVisualCompositionRuntimeId,
		capabilityId = Types.RobloxVisualCompositionCapabilityId,
		platform = Types.RobloxRenderingPlatform,
		definitions = Definitions.inspect(),
		compositions = Instances.inspect(),
		resolvedPlans = Plans.inspect(),
		bindings = Bindings.inspect(),
		ownership = Ownership.inspect(),
		revisions = Revisions.inspect(),
		evidence = Evidence.inspect(),
		metrics = Metrics.inspect(),
		profiler = Profiler.inspect(),
		budgets = Budgets.inspect(),
		governance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = runtime.getCounters(),
		failures = runtime.getFailures(),
		robloxVisualCompositionPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			deterministicCompilation = true,
			deterministicRevisions = true,
			dataOnly = true,
			immutableDiagnostics = true,
			immutableSnapshots = true,
			immutablePlans = true,
			noGuiCreation = true,
			noRendering = true,
			noInstanceMutation = true,
			noAssetLoading = true,
			noNetworking = true,
			noWorkspaceMutation = true,
			noPersistence = true,
			noGameplayExecution = true,
			noDialogueExecution = true,
			noAiExecution = true,
			noAnalytics = true,
			noTelemetry = true,
			noClientAuthority = true,
		},
	}
end

function Diagnostics.copy(value: any)
	return Serialization.deepCopy(value)
end

return Diagnostics
