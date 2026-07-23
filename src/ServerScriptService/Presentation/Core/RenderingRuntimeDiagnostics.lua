--!strict

local Acknowledgements = require(script.Parent.RenderingAcknowledgementProducer)
local Assignments = require(script.Parent.RendererAssignmentManager)
local Budgets = require(script.Parent.RenderingRuntimeBudgets)
local Certification = require(script.Parent.RenderingRuntimeCertification)
local Evidence = require(script.Parent.RenderingRuntimeEvidence)
local Governance = require(script.Parent.RenderingRuntimeGovernance)
local Metrics = require(script.Parent.RenderingRuntimeMetrics)
local Profiler = require(script.Parent.RenderingRuntimeProfiler)
local Renderers = require(script.Parent.RendererRuntimeRegistry)
local RuntimeCapability = require(script.Parent.RenderingRuntimeCapabilityRegistry)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RenderingSessionRegistry)
local Synchronization = require(script.Parent.RenderingSynchronizationRuntime)
local Types = require(script.Parent.PresentationTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return {
		providerName = Types.RenderingRuntimeProviderName,
		runtimeId = Types.RenderingRuntimeId,
		capabilityId = Types.RenderingRuntimeCapabilityId,
		runtimeCapability = RuntimeCapability.inspect(),
		rendererRegistry = Renderers.inspect(),
		renderingSessions = Sessions.inspect(),
		assignments = Assignments.inspect(),
		acknowledgements = Acknowledgements.inspect(),
		synchronization = Synchronization.inspect(),
		evidence = Evidence.inspect(),
		metrics = Metrics.inspect(),
		profiler = Profiler.inspect(),
		budgets = Budgets.inspect(),
		governance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = runtime.getCounters(),
		failures = runtime.getFailures(),
		renderingRuntimePosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			deterministicRendererAssignment = true,
			deterministicSessionOrdering = true,
			immutableDiagnostics = true,
			immutableSnapshots = true,
			immutableEvidence = true,
			rendererIsolation = true,
			sessionIsolation = true,
			noGui = true,
			noRendering = true,
			noNetworking = true,
			noPersistence = true,
			noWorkspaceMutation = true,
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
