--!strict

local Acknowledgements = require(script.Parent.PresentationAcknowledgementProducer)
local Budgets = require(script.Parent.PresentationBudgets)
local Capability = require(script.Parent.PresentationCapabilityRegistry)
local Certification = require(script.Parent.PresentationCertification)
local Consumers = require(script.Parent.PresentationConsumerRegistry)
local Evidence = require(script.Parent.PresentationEvidence)
local Governance = require(script.Parent.PresentationGovernance)
local Lifecycle = require(script.Parent.PresentationLifecycleManager)
local Metrics = require(script.Parent.PresentationMetrics)
local Profiler = require(script.Parent.PresentationProfiler)
local Queue = require(script.Parent.PresentationQueue)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.PresentationSessionRegistry)
local Synchronization = require(script.Parent.PresentationSynchronizationRuntime)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.PresentationRuntimeValidation)

local Runtime = {}
local shutdown = false
local counters = {
	sessionsCreated = 0,
	consumersRegistered = 0,
	acknowledgementsProduced = 0,
	synchronizationResolutions = 0,
	validationFailures = 0,
	lastFailure = nil :: any?,
}

local function fail(code: string, message: string, payload: any?)
	counters.validationFailures += 1
	counters.lastFailure = {
		code = code,
		message = message,
		payload = Serialization.diagnosticCopy(payload or {}),
	}
	Metrics.increment("validationFailures")
	Evidence.record("PresentationRuntimeFailure", counters.lastFailure, Types.Limits.MaxEvidence)
	return { ok = false, code = code, message = message }
end

function Runtime.registerCapability()
	return Capability.ensureDefault()
end

function Runtime.registerConsumer(consumer: any)
	if shutdown then
		return fail(Types.RuntimeFailureType.RuntimeShutdown, "runtime is shut down", consumer)
	end
	local result = Consumers.register(consumer)
	if not result.ok then
		return fail(result.code, result.message, consumer)
	end
	counters.consumersRegistered += 1
	return result
end

function Runtime.createSession(request: any)
	if shutdown then
		return fail(Types.RuntimeFailureType.RuntimeShutdown, "runtime is shut down", request)
	end
	if type(request) ~= "table" or Consumers.get(request.consumerId) == nil then
		return fail(Types.RuntimeFailureType.UnknownConsumer, "unknown consumer", request)
	end
	local result = Sessions.create(request)
	if not result.ok then
		return fail(result.code, result.message, request)
	end
	counters.sessionsCreated += 1
	Profiler.record(result.session.presentationSessionId, "sessionCreateDuration", 0)
	return result
end

function Runtime.enqueueSession(sessionId: string)
	local result = Queue.enqueue(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { sessionId = sessionId })
	end
	Profiler.record(sessionId, "queueLatency", 0)
	return result
end

function Runtime.assignSession(sessionId: string)
	local result = Queue.assign(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { sessionId = sessionId })
	end
	Profiler.record(sessionId, "assignmentLatency", 0)
	return result
end

function Runtime.transitionSession(sessionId: string, state: string)
	local result = Lifecycle.transition(sessionId, state)
	if not result.ok then
		return fail(result.code, result.message, { sessionId = sessionId, state = state })
	end
	Profiler.record(sessionId, "lifecycleTransitionDuration", 0)
	return result
end

function Runtime.produceAcknowledgement(request: any)
	if shutdown then
		return fail(Types.RuntimeFailureType.RuntimeShutdown, "runtime is shut down", request)
	end
	local result = Acknowledgements.produce(request)
	if not result.ok then
		return fail(result.code, result.message, request)
	end
	counters.acknowledgementsProduced += 1
	Profiler.record(request.presentationSessionId, "acknowledgementLatency", 0)
	return result
end

function Runtime.resolveSynchronization(sessionId: string)
	local result = Synchronization.resolve(sessionId)
	if not result.ok then
		return fail(result.code, result.message, { sessionId = sessionId })
	end
	counters.synchronizationResolutions += 1
	Profiler.record(sessionId, "synchronizationLatency", 0)
	return result
end

function Runtime.inspect()
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		presentationRuntimePosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			deterministicQueueOrdering = true,
			deterministicLifecycle = true,
			noRendering = true,
			noGui = true,
			noNetworking = true,
			noRemoteEvents = true,
			noRemoteFunctions = true,
			noPersistence = true,
			noWorkspaceMutation = true,
			noGameplayExecution = true,
			noDialogueExecution = true,
			noClientAuthority = true,
			noAnalytics = true,
			noTelemetry = true,
		},
		capability = Capability.inspect(),
		activeSessions = Sessions.inspect(),
		queueState = Queue.inspect(),
		consumers = Consumers.inspect(),
		acknowledgements = Acknowledgements.inspect(),
		synchronization = Synchronization.inspect(),
		evidence = Evidence.inspect(),
		metrics = Metrics.inspect(),
		profiler = Profiler.inspect(),
		budgets = Budgets.inspect(),
		governance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = counters,
	})
end

function Runtime.getSnapshot()
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		presentationRuntimeSnapshot = Runtime.inspect(),
	})
end

function Runtime.validate(): (boolean, string?)
	return Validation.validate()
end

function Runtime.shutdown()
	shutdown = true
	Evidence.record("PresentationRuntimeShutdown", {}, Types.Limits.MaxEvidence)
end

function Runtime.reset()
	shutdown = false
	for key in pairs(counters) do
		if key == "lastFailure" then
			counters[key] = nil
		else
			counters[key] = 0
		end
	end
	Acknowledgements.clear()
	Capability.clear()
	Consumers.clear()
	Evidence.clear()
	Metrics.clear()
	Profiler.clear()
	Queue.clear()
	Sessions.clear()
	Synchronization.clear()
	Runtime.registerCapability()
	Evidence.record("PresentationRuntimeReset", {}, Types.Limits.MaxEvidence)
end

Runtime.reset()

return Runtime
