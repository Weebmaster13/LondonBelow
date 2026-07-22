--!strict

local ConsumerRegistry = require(script.Parent.ConsumerRegistry)
local DependencyRegistry = require(script.Parent.DependencyRegistry)
local Diagnostics = require(script.Parent.IntegrationDiagnostics)
local Evidence = require(script.Parent.MessagingEvidence)
local Inspection = require(script.Parent.IntegrationInspection)
local Lifecycle = require(script.Parent.ConsumerLifecycle)
local Metrics = require(script.Parent.MessagingMetrics)
local Profiler = require(script.Parent.IntegrationProfiler)
local RuntimeDiscovery = require(script.Parent.RuntimeDiscovery)
local Serialization = require(script.Parent.MessagingSerialization)
local Snapshots = require(script.Parent.IntegrationSnapshots)
local SubscriptionRegistry = require(script.Parent.SubscriptionRegistry)
local Types = require(script.Parent.MessagingTypes)

local Runtime = {}
local shutdown = false
local counters = {
	registeredConsumers = 0,
	validatedConsumers = 0,
	initializedConsumers = 0,
	runningConsumers = 0,
	shutdownConsumers = 0,
	registeredSubscriptions = 0,
	dependencyValidations = 0,
	failed = 0,
	lastFailure = nil :: any?,
}

Runtime.Responsibilities = {
	"consumer registration",
	"messaging contracts",
	"dependency mapping",
	"subscription ownership",
	"consumer lifecycle",
	"runtime discovery",
	"integration diagnostics",
}

local function failure(code: string, message: string, payload: any?)
	local record = { code = code, message = message, payload = Serialization.deepCopy(payload) }
	counters.failed += 1
	counters.lastFailure = record
	Metrics.increment("failures")
	Evidence.record("integration failure", record)
	return { ok = false, code = code, message = message }
end

local function registerCoreConsumer()
	ConsumerRegistry.register({
		consumerId = Types.CoreConsumerId,
		ownerRuntime = Types.ProviderName,
		version = "1",
		capabilities = { "consumerRegistration", "dependencyValidation", "runtimeDiscovery" },
		subscriptions = {},
		publicInterfaces = { "runtime.messaging.integration" },
		requiredInterfaces = {},
		lifecycle = {
			Types.LifecycleState.Created,
			Types.LifecycleState.Registered,
			Types.LifecycleState.Validated,
			Types.LifecycleState.Initialized,
			Types.LifecycleState.Ready,
			Types.LifecycleState.Running,
			Types.LifecycleState.Suspended,
			Types.LifecycleState.Shutdown,
		},
		dependencies = {},
		authorityLevel = Types.AuthorityLevel.Core,
		supportedCommands = {},
		supportedEvents = {},
		supportedQueries = {},
	})
	Lifecycle.create(Types.CoreConsumerId)
	RuntimeDiscovery.indexConsumer(Types.CoreConsumerId)
end

function Runtime.registerConsumer(contract: any)
	if shutdown then
		return failure(Types.FailureType.ValidationFailure, "runtime is shut down", contract)
	end
	local result = ConsumerRegistry.register(contract)
	if not result.ok then
		return failure(result.code, result.message, contract)
	end
	Lifecycle.create(result.consumerId)
	RuntimeDiscovery.indexConsumer(result.consumerId)
	counters.registeredConsumers = ConsumerRegistry.count()
	Metrics.set({ registeredConsumers = counters.registeredConsumers })
	return result
end

function Runtime.registerSubscription(subscription: any)
	if shutdown then
		return failure(Types.FailureType.ValidationFailure, "runtime is shut down", subscription)
	end
	local result = SubscriptionRegistry.register(subscription)
	if not result.ok then
		return failure(result.code, result.message, subscription)
	end
	counters.registeredSubscriptions = SubscriptionRegistry.count()
	Metrics.set({ subscriptions = counters.registeredSubscriptions })
	return result
end

function Runtime.validateDependencies()
	local result = DependencyRegistry.validate()
	if not result.ok then
		return failure(result.code, "dependency validation failed", result.failure)
	end
	counters.dependencyValidations += 1
	counters.validatedConsumers = ConsumerRegistry.count()
	Metrics.set({
		activeConsumers = counters.runningConsumers,
		dependencyDepth = #result.order,
	})
	for _, consumerId in ipairs(result.order) do
		if Lifecycle.get(consumerId) == Types.LifecycleState.Registered then
			Lifecycle.transition(consumerId, Types.LifecycleState.Validated)
		end
	end
	return result
end

function Runtime.initializeConsumers()
	local validation = Runtime.validateDependencies()
	if not validation.ok then
		return validation
	end
	for _, consumerId in ipairs(validation.order) do
		if Lifecycle.get(consumerId) == Types.LifecycleState.Validated then
			Lifecycle.transition(consumerId, Types.LifecycleState.Initialized)
			Profiler.recordInitialization(consumerId, 0)
			Lifecycle.transition(consumerId, Types.LifecycleState.Ready)
			counters.initializedConsumers += 1
			Metrics.increment("initializationCount")
		end
	end
	return { ok = true, code = "Ok", order = validation.order }
end

function Runtime.startConsumers()
	local initialization = Runtime.initializeConsumers()
	if not initialization.ok then
		return initialization
	end
	for _, consumerId in ipairs(initialization.order) do
		if Lifecycle.get(consumerId) == Types.LifecycleState.Ready then
			Lifecycle.transition(consumerId, Types.LifecycleState.Running)
			counters.runningConsumers += 1
		end
	end
	Metrics.set({ activeConsumers = counters.runningConsumers })
	return { ok = true, code = "Ok", order = initialization.order }
end

function Runtime.suspendConsumer(consumerId: string)
	return Lifecycle.transition(consumerId, Types.LifecycleState.Suspended)
end

function Runtime.shutdownConsumers()
	local order = DependencyRegistry.getShutdownOrder()
	for _, consumerId in ipairs(order) do
		local state = Lifecycle.get(consumerId)
		if state == Types.LifecycleState.Running or state == Types.LifecycleState.Suspended then
			Lifecycle.transition(consumerId, Types.LifecycleState.Shutdown)
			Profiler.recordShutdown(consumerId, 0)
			counters.shutdownConsumers += 1
			Metrics.increment("shutdownCount")
		end
	end
	counters.runningConsumers = 0
	Metrics.set({ activeConsumers = 0 })
	return { ok = true, code = "Ok", order = order }
end

function Runtime.resolveInterface(interfaceId: string)
	return RuntimeDiscovery.resolve(interfaceId)
end

function Runtime.resolveSubscriptions(eventType: string)
	return SubscriptionRegistry.resolve(eventType)
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return Snapshots.capture(Runtime)
end

function Runtime.getInspection()
	return Inspection.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	local result = DependencyRegistry.validate()
	if not result.ok then
		return false, result.code
	end
	return true, nil
end

function Runtime.shutdown()
	shutdown = true
	Runtime.shutdownConsumers()
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
	ConsumerRegistry.clear()
	DependencyRegistry.clear()
	SubscriptionRegistry.clear()
	Lifecycle.clear()
	RuntimeDiscovery.clear()
	Evidence.clear()
	Metrics.clear()
	Profiler.clear()
	registerCoreConsumer()
end

function Runtime.isShutdown(): boolean
	return shutdown
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

function Runtime.getConsumers()
	return ConsumerRegistry.inspect()
end

function Runtime.getDependencyGraph()
	return DependencyRegistry.inspect()
end

function Runtime.getSubscriptions()
	return SubscriptionRegistry.inspect()
end

function Runtime.getDiscovery()
	return RuntimeDiscovery.inspect()
end

Runtime.reset()

return Runtime
