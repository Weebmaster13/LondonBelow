--!strict

local Acknowledgements = require(script.Parent.AcknowledgementExecutionEngine)
local Certification = require(script.Parent.PresentationExecutionCertification)
local Evidence = require(script.Parent.PresentationExecutionEvidence)
local Governance = require(script.Parent.PresentationExecutionGovernance)
local Metrics = require(script.Parent.PresentationExecutionMetrics)
local Profiler = require(script.Parent.PresentationExecutionProfiler)
local Queue = require(script.Parent.PresentationExecutionQueue)
local Scheduler = require(script.Parent.PresentationExecutionScheduler)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.SessionExecutionEngine)
local Synchronization = require(script.Parent.SynchronizationExecutionEngine)
local Types = require(script.Parent.PresentationTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ExecutionProviderName,
		presentationExecutionPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			deterministicScheduler = true,
			deterministicQueue = true,
			deterministicLifecycle = true,
			noRendering = true,
			noGui = true,
			noNetworking = true,
			noRemoteEvents = true,
			noRemoteFunctions = true,
			noPersistence = true,
			noWorkspaceMutation = true,
			noGameplayExecution = true,
			noClientAuthority = true,
			noAnalytics = true,
			noTelemetry = true,
		},
		scheduler = Scheduler.inspect(),
		executionQueue = Queue.inspect(),
		executingSessions = Sessions.inspect(),
		acknowledgements = Acknowledgements.inspect(),
		synchronization = Synchronization.inspect(),
		failures = runtime.getFailures(),
		evidence = Evidence.inspect(),
		metrics = Metrics.inspect(),
		profiler = Profiler.inspect(),
		governance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = runtime.getCounters(),
	})
end

return Diagnostics
