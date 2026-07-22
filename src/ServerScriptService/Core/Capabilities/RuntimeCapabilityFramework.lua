--!strict

local DependencyGraph = require(script.Parent.CapabilityDependencyGraph)
local Diagnostics = require(script.Parent.CapabilityDiagnostics)
local Discovery = require(script.Parent.CapabilityDiscovery)
local Evidence = require(script.Parent.CapabilityEvidence)
local Health = require(script.Parent.CapabilityHealth)
local Lifecycle = require(script.Parent.CapabilityLifecycle)
local Metrics = require(script.Parent.CapabilityMetrics)
local Profiler = require(script.Parent.CapabilityProfiler)
local Registry = require(script.Parent.CapabilityRegistry)
local Serialization = require(script.Parent.CapabilitySerialization)
local Snapshots = require(script.Parent.CapabilitySnapshots)
local Types = require(script.Parent.CapabilityTypes)

local Runtime = {}
local shutdown = false
local counters = {
	registeredCapabilities = 0,
	validatedCapabilities = 0,
	initializedCapabilities = 0,
	readyCapabilities = 0,
	runningCapabilities = 0,
	suspendedCapabilities = 0,
	shutdownCapabilities = 0,
	discoveryRequests = 0,
	lastFailure = nil :: any?,
}

Runtime.Responsibilities = {
	"capability registration",
	"capability discovery",
	"capability lifecycle",
	"capability versioning",
	"capability dependency validation",
	"capability health metadata",
	"capability diagnostics",
	"capability snapshots",
	"capability evidence",
}

local function failure(code: string, message: string, payload: any?)
	counters.lastFailure =
		{ code = code, message = message, payload = Serialization.deepCopy(payload) }
	Evidence.record("capability failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

local function registerCoreCapability()
	Runtime.registerCapability({
		capabilityId = Types.ProviderName .. ".self",
		version = "1",
		owner = "Core",
		category = Types.Category.Core,
		authority = Types.Authority.Core,
		interfaces = {
			{
				interfaceId = "runtime.capability.registration",
				version = "1",
				methods = { "registerCapability", "resolveInterface", "inspect" },
			},
		},
		dependencies = {},
		healthProvider = "RuntimeCapabilityCoordinator.inspect",
		diagnosticsProvider = "RuntimeCapabilityCoordinator.inspect",
		snapshotProvider = Types.ProviderName,
		metadata = { foundationPhase = 170 },
	})
	Runtime.validateCapability(Types.ProviderName .. ".self")
	Runtime.initializeCapability(Types.ProviderName .. ".self")
	Runtime.markReady(Types.ProviderName .. ".self")
end

function Runtime.registerCapability(definition: any)
	if shutdown then
		return failure(Types.FailureType.RuntimeShutdown, "runtime is shut down", definition)
	end
	local result = Registry.register(definition)
	if not result.ok then
		return failure(result.code, result.message, definition)
	end
	Lifecycle.create(result.capabilityId)
	counters.registeredCapabilities = Registry.count()
	Metrics.set("registeredCapabilities", Registry.count())
	return result
end

function Runtime.validateCapability(capabilityId: string)
	local result = DependencyGraph.validate(capabilityId)
	if not result.ok then
		Metrics.increment("dependencyFailures")
		return failure(result.code, result.message, { capabilityId = capabilityId })
	end
	local lifecycle = Lifecycle.transition(capabilityId, Types.LifecycleState.Validated)
	if lifecycle.ok then
		counters.validatedCapabilities += 1
	end
	return lifecycle
end

function Runtime.initializeCapability(capabilityId: string)
	local result = Lifecycle.transition(capabilityId, Types.LifecycleState.Initialized)
	if result.ok then
		counters.initializedCapabilities += 1
		Profiler.record(capabilityId, "initializationDuration", 0)
	end
	return result
end

function Runtime.markReady(capabilityId: string)
	local result = Lifecycle.transition(capabilityId, Types.LifecycleState.Ready)
	if result.ok then
		counters.readyCapabilities += 1
		Health.publish(
			capabilityId,
			Types.Health.Healthy,
			Types.Readiness.Ready,
			Types.Availability.Available
		)
	end
	return result
end

function Runtime.activateCapability(capabilityId: string)
	local dependencyValidation = DependencyGraph.validate(capabilityId)
	if not dependencyValidation.ok then
		return failure(dependencyValidation.code, dependencyValidation.message, {
			capabilityId = capabilityId,
		})
	end
	local result = Lifecycle.transition(capabilityId, Types.LifecycleState.Running)
	if result.ok then
		counters.runningCapabilities += 1
		Metrics.set("runningCapabilities", counters.runningCapabilities)
		Evidence.record("capability activated", { capabilityId = capabilityId })
	end
	return result
end

function Runtime.suspendCapability(capabilityId: string, reason: string)
	local result = Lifecycle.transition(capabilityId, Types.LifecycleState.Suspended)
	if result.ok then
		counters.suspendedCapabilities += 1
		Health.publish(
			capabilityId,
			Types.Health.Degraded,
			Types.Readiness.Blocked,
			Types.Availability.Suspended
		)
		Evidence.record("capability suspended", { capabilityId = capabilityId, reason = reason })
	end
	return result
end

function Runtime.recoverCapability(capabilityId: string)
	local result = Lifecycle.transition(capabilityId, Types.LifecycleState.Ready)
	if result.ok then
		Metrics.increment("recoveryCount")
		Health.publish(
			capabilityId,
			Types.Health.Healthy,
			Types.Readiness.Ready,
			Types.Availability.Available
		)
		Evidence.record("capability recovered", { capabilityId = capabilityId })
	end
	return result
end

function Runtime.shutdownCapability(capabilityId: string)
	local result = Lifecycle.transition(capabilityId, Types.LifecycleState.Shutdown)
	if result.ok then
		counters.shutdownCapabilities += 1
		Health.publish(
			capabilityId,
			Types.Health.Unavailable,
			Types.Readiness.NotReady,
			Types.Availability.Unavailable
		)
		Evidence.record("capability shutdown", { capabilityId = capabilityId })
	end
	return result
end

function Runtime.resolveInterface(interfaceId: string, version: string, owner: string?)
	local result = Discovery.resolve(interfaceId, version, owner)
	if result.ok then
		counters.discoveryRequests += 1
	end
	return result
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return Snapshots.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return true, nil
end

function Runtime.shutdown()
	shutdown = true
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
	Registry.clear()
	Lifecycle.clear()
	DependencyGraph.clear()
	Discovery.clear()
	Health.clear()
	Evidence.clear()
	Metrics.clear()
	Profiler.clear()
	registerCoreCapability()
end

function Runtime.isShutdown(): boolean
	return shutdown
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

Runtime.reset()

return Runtime
