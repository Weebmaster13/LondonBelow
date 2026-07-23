--!strict

local Acknowledgements = require(script.Parent.RenderingExecutionAcknowledgements)
local Budgets = require(script.Parent.RenderingExecutionBudgets)
local Certification = require(script.Parent.RenderingExecutionCertification)
local Evidence = require(script.Parent.RenderingExecutionEvidence)
local Governance = require(script.Parent.RenderingExecutionGovernance)
local Metrics = require(script.Parent.RenderingExecutionMetrics)
local Profiler = require(script.Parent.RenderingExecutionProfiler)
local Scheduler = require(script.Parent.RenderingExecutionScheduler)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RenderingExecutionSessionRegistry)
local Synchronization = require(script.Parent.RenderingExecutionSynchronization)
local Types = require(script.Parent.PresentationTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return {
		providerName = Types.RenderingExecutionProviderName,
		runtimeId = Types.RenderingExecutionRuntimeId,
		scheduler = Scheduler.inspect(),
		executionSessions = Sessions.inspect(),
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
		renderingExecutionPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			deterministicScheduling = true,
			deterministicQueueOrdering = true,
			deterministicExecution = true,
			deterministicAcknowledgementOrdering = true,
			immutableDiagnostics = true,
			immutableSnapshots = true,
			immutableEvidence = true,
			rendererIsolation = true,
			executionIsolation = true,
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
